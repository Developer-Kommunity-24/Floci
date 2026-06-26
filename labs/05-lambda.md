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

Enable hot reload so your function code updates automatically without re-deploying:

Add to your `compose.yaml`:

```yaml
services:
  floci:
    image: floci/floci:latest
    volumes:
      # Podman socket — exposes the container runtime to Floci for Lambda execution
      - /run/podman/podman.sock:/var/run/docker.sock
      - ./lambda-demo:/hot-reload   # mount your source directory
    environment:
      FLOCI_SERVICES_LAMBDA_HOT_RELOAD_ENABLED: "true"
```

> 💡 **macOS (Podman machine):** the socket path is inside the VM. Get it with:
> ```bash
> podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}'
> ```
> Use that path in the volume mount above.

Then deploy pointing at the hot-reload S3 bucket:

```bash
aws lambda create-function \
  --function-name hello-hot \
  --runtime nodejs22.x \
  --role arn:aws:iam::000000000000:role/lambda-role \
  --handler index.handler \
  --code S3Bucket=hot-reload,S3Key=/path/to/lambda-demo
```

Now edits to `index.mjs` take effect on the next invocation — no re-zip, no re-deploy.

---

## Challenge 🏆

> Build a Lambda function that:
> 1. Accepts an event with `{"action": "write", "key": "...", "value": "..."}` or `{"action": "read", "key": "..."}`
> 2. Writes to / reads from an SSM Parameter Store key
> 3. Deploy it to Floci and invoke it both ways

---

➡️ Next: [Lab 06 — Developer Workflow & CI](./06-developer-workflow.md)
