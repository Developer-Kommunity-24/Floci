# Lab 01 — Setup & First Start

**Duration:** ~15 min  
**Goal:** Install Floci, start the emulator, and confirm it's working.

---

## Step 1 — Install Prerequisites

```bash
# Floci CLI
brew install floci-io/tap/floci

# AWS CLI (skip if already installed)
brew install awscli

# jq — pretty-print JSON responses
brew install jq
```

Verify:

```bash
floci --version
aws --version
jq --version
```

---

## Step 2 — Start Floci

```bash
floci start
```

You should see output like:

```
✔ Floci is running at http://localhost:4566
  Version : 1.x.x
  Services: 59 available
```

> **Alternative — Podman Compose:**
> If you prefer Podman Compose, create a `compose.yaml` in your project root:
>
> ```yaml
> services:
>   floci:
>     image: floci/floci:latest
>     ports:
>       - "4566:4566"
> ```
>
> Then run: `podman compose up -d`

---

## Step 3 — Point Your AWS Tools at Floci

```bash
eval $(floci env)
```

This exports:

```bash
export AWS_ENDPOINT_URL=http://localhost:4566
export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
```

> 💡 You can also set these manually. Floci accepts **any** key/secret — no real credentials required.

---

## Step 4 — Verify the Emulator is Healthy

```bash
curl -s http://localhost:4566/_floci/health | jq .
```

Expected response:

```json
{
  "status": "UP",
  "version": "1.x.x",
  "services": {
    "s3": "running",
    "sqs": "running",
    "dynamodb": "running",
    ...
  }
}
```

You can also open the Floci UI in your browser:

```
http://localhost:4566
```

---

## Step 5 — Smoke Test with S3

```bash
aws s3 mb s3://test-bucket
aws s3 ls
```

Expected:

```
make_bucket: test-bucket
2026-06-25 00:00:00 test-bucket
```

🎉 **Floci is running!** Move on to [Lab 02 — S3](./02-s3.md).

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `floci: command not found` | Run `brew install floci-io/tap/floci` |
| Port 4566 already in use | `lsof -i :4566` then kill the process |
| Podman machine not running | `podman machine start` |
| `connection refused` | Wait a few seconds and retry; Floci is still starting |
