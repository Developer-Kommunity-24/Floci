# Lab 05 — Lambda: Deploy & Invoke Locally

**Duration:** ~20 min  
**Goal:** Write a Node.js Lambda function, deploy it to Floci, invoke it synchronously and asynchronously, and update its code.

---

## Prerequisites

```bash
export AWS_ENDPOINT_URL=http://localhost:4566
export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_PAGER=""

node --version   # Node.js required to write the function locally
```

> 💡 Already set from Lab 01? Just verify: `echo $AWS_ENDPOINT_URL`

> ⚠️ **Podman users — one-time setup required before Lambda works.**  
> Podman's `host-gateway` feature (used by Floci to wire Lambda containers) needs to be enabled inside the Podman VM. Run this **once**:
>
> ```bash
> # 1. Configure host-gateway IP inside the Podman VM
> podman machine ssh "sudo mkdir -p /etc/containers && printf '[containers]\nhost_containers_internal_ip = \"10.88.0.1\"\n' | sudo tee /etc/containers/containers.conf"
>
> # 2. Restart the Podman socket daemon to pick up the change
> podman machine ssh "sudo systemctl restart podman.socket"
>
> # 3. Restart Floci
> podman compose down && podman compose up -d
> ```
>
> Your `compose.yaml` must also include these two env vars (already in the repo's `compose.yaml`):
> ```yaml
> environment:
>   FLOCI_SERVICES_LAMBDA_DOCKER_NETWORK: floci_default
>   FLOCI_SERVICES_LAMBDA_DOCKER_HOST_OVERRIDE: floci
> ```

---

## Part A — Write the Function

```bash
mkdir -p lambda-demo && cd lambda-demo
```

Create `index.mjs`:

```bash
cat > index.mjs << 'EOF'
export const handler = async (event) => {
  console.log("Received event:", JSON.stringify(event, null, 2));

  const name = event.name ?? "World";
  const timestamp = new Date().toISOString();

  return {
    statusCode: 200,
    body: JSON.stringify({
      message: `Hello, ${name}!`,
      timestamp,
    }),
  };
};
EOF
```

---

## Part B — Package the Function

```bash
zip function.zip index.mjs
ls -lh function.zip
```

---

## Part C — Deploy to Floci

```bash
aws lambda create-function \
  --function-name hello-floci \
  --runtime nodejs22.x \
  --role arn:aws:iam::000000000000:role/lambda-role \
  --handler index.handler \
  --zip-file fileb://function.zip
```

### Verify deployment

```bash
aws lambda get-function --function-name hello-floci | jq .Configuration
```

### List all functions

```bash
aws lambda list-functions | jq '.Functions[] | {name: .FunctionName, runtime: .Runtime}'
```

---

## Part D — Invoke the Function

### Synchronous invoke

```bash
aws lambda invoke \
  --function-name hello-floci \
  --payload '{"name":"Developer Kommunity"}' \
  --cli-binary-format raw-in-base64-out \
  response.json

cat response.json | jq .
```

Expected output:

```json
{
  "statusCode": 200,
  "body": "{\"message\":\"Hello, Developer Kommunity!\",\"timestamp\":\"2026-06-25T...\"}"
}
```

### Invoke with no payload

```bash
aws lambda invoke \
  --function-name hello-floci \
  --cli-binary-format raw-in-base64-out \
  response2.json

cat response2.json | jq .
```

### Asynchronous invoke (fire and forget)

```bash
aws lambda invoke \
  --function-name hello-floci \
  --invocation-type Event \
  --payload '{"name":"Async Call"}' \
  --cli-binary-format raw-in-base64-out \
  /dev/null

echo "Exit code: $?"   # 202 = accepted
```

---

## Part E — Update the Function

Modify the handler to add more fields:

```bash
cat > index.mjs << 'EOF'
export const handler = async (event) => {
  console.log("Received event:", JSON.stringify(event, null, 2));

  const name = event.name ?? "World";
  const timestamp = new Date().toISOString();
  const region = process.env.AWS_DEFAULT_REGION ?? "unknown";

  return {
    statusCode: 200,
    body: JSON.stringify({
      message: `Hello, ${name}!`,
      timestamp,
      region,
      version: "v2",
    }),
  };
};
EOF

zip function.zip index.mjs

aws lambda update-function-code \
  --function-name hello-floci \
  --zip-file fileb://function.zip | jq .LastModified

# Wait for update to complete
aws lambda wait function-updated --function-name hello-floci

# Invoke the updated function
aws lambda invoke \
  --function-name hello-floci \
  --payload '{"name":"Updated Lambda"}' \
  --cli-binary-format raw-in-base64-out \
  response3.json

cat response3.json | jq .
```

---

## Part F — Environment Variables

```bash
aws lambda update-function-configuration \
  --function-name hello-floci \
  --environment 'Variables={APP_ENV=local,FEATURE_FLAG=true}'

aws lambda get-function-configuration \
  --function-name hello-floci \
  --query Environment | jq .
```

---

## Part G — Hot Reload (Bonus)

Hot reload lets you edit `index.mjs` and have it take effect on the next invocation — no re-zip, no re-deploy.

**How it works:** Floci passes the `S3Key` path directly to Podman as a bind-mount source for the Lambda container. That path must be an **absolute path visible to the Podman VM** (not just the macOS host).

Since Podman machine shares your macOS home directory into the VM at the same path, this works:

1. Update `compose.yaml` — remove the `/hot-reload` volume (not needed) and add the allowed paths env var:

```yaml
services:
  floci:
    image: floci/floci:latest
    # ... other config unchanged ...
    environment:
      FLOCI_SERVICES_LAMBDA_HOT_RELOAD_ENABLED: "true"
      FLOCI_SERVICES_LAMBDA_HOT_RELOAD_ALLOWED_PATHS: /Users
```

2. Restart Floci:

```bash
podman compose down && podman compose up -d
```

3. Deploy pointing at the absolute path of your code directory:

```bash
# Make sure you're in the lambda-demo directory
cd ~/floci-workshop/lambda-demo   # or wherever your lambda-demo lives

aws lambda create-function \
  --function-name hello-hot \
  --runtime nodejs22.x \
  --role arn:aws:iam::000000000000:role/lambda-role \
  --handler index.handler \
  --code S3Bucket=hot-reload,S3Key=$(pwd)
```

4. Invoke it:

```bash
aws lambda invoke \
  --function-name hello-hot \
  --payload '{"name":"Hot Reload"}' \
  --cli-binary-format raw-in-base64-out \
  response-hot.json

cat response-hot.json | jq .
```

5. Now edit `index.mjs` (change the message, add a field), then invoke again — the change takes effect immediately, no redeployment needed.

> ⚠️ `FLOCI_SERVICES_LAMBDA_HOT_RELOAD_ALLOWED_PATHS=/Users` is required on macOS — it whitelists the bind-mount source so Floci doesn't reject the path.

---

## Challenge 🏆

> Build a Lambda function that:
> 1. Accepts an event with `{"action": "write", "key": "...", "value": "..."}` or `{"action": "read", "key": "..."}`
> 2. Writes to / reads from an SSM Parameter Store key
> 3. Deploy it to Floci and invoke it both ways

---

➡️ Next: [Lab 06 — Developer Workflow & CI](./06-developer-workflow.md)
