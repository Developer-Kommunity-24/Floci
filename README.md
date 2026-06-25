# Any Cloud, Locally: Hands-on with Floci Cloud Emulators

> **Workshop** · Developer Kommunity · 25 June 2026

Run AWS cloud services on your laptop — no cloud account, no auth tokens, no surprises.

---

## 🗺️ Agenda

| # | Module | Duration |
|---|--------|----------|
| 0 | Intro & Why Local Cloud Matters | 10 min |
| 1 | [Setup & First Start](./labs/01-setup.md) | 15 min |
| 2 | [S3 — Buckets & Objects](./labs/02-s3.md) | 15 min |
| 3 | [SQS + DynamoDB](./labs/03-sqs-dynamodb.md) | 20 min |
| 4 | [SNS Fan-out](./labs/04-sns-fanout.md) | 15 min |
| 5 | [Lambda — Deploy & Invoke Locally](./labs/05-lambda.md) | 20 min |
| 6 | [Developer Workflow & CI](./labs/06-developer-workflow.md) | 15 min |
| 7 | [Floci vs. Mocks vs. LocalStack vs. Real Cloud](./labs/07-floci-vs-others.md) | 10 min |
|   | Q&A | 10 min |

**Total: ~2 hours**

---

## 🎯 What You'll Learn

- Start a full local AWS emulator in seconds with `floci start`
- Create and test real cloud resources (S3, SQS, DynamoDB, SNS, Lambda) from your terminal
- Plug Floci into your dev loop and CI pipeline
- Understand the trade-offs between mocks, Floci, LocalStack, and real cloud environments

---

## 🛠️ Prerequisites

Pick your OS and container runtime — all combinations are supported.

### macOS

| Tool | Docker option | Podman option |
|------|--------------|---------------|
| Container runtime | `brew install --cask docker` | `brew install podman && podman machine init && podman machine start` |
| Compose | Bundled with Docker Desktop | `brew install podman-compose` |
| Floci CLI | `brew install floci-io/tap/floci` | `brew install floci-io/tap/floci` |
| AWS CLI | `brew install awscli` | `brew install awscli` |
| jq | `brew install jq` | `brew install jq` |

### Windows

> ⚠️ **WSL2 required.** Enable it first: `wsl --install` in PowerShell (Admin), then reboot.

| Tool | Docker option | Podman option |
|------|--------------|---------------|
| Container runtime | [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/) | [Podman Desktop](https://podman-desktop.io/) + `winget install RedHat.Podman` |
| Compose | Bundled with Docker Desktop | `winget install RedHat.Podman` (includes `podman compose`) |
| Floci CLI | Run inside WSL2 terminal: `brew install floci-io/tap/floci` | Same |
| AWS CLI | `winget install Amazon.AWSCLI` | `winget install Amazon.AWSCLI` |
| jq | `winget install jqlang.jq` | `winget install jqlang.jq` |

> **No AWS account required.** All resources run locally inside Floci.

---

## ⚡ 60-Second Quick Start

```bash
# 1. Start Floci
floci start

# 2. Point your AWS tools at Floci
eval $(floci env)

# 3. Try it out
aws s3 mb s3://hello-floci
echo "hello, world" | aws s3 cp - s3://hello-floci/hello.txt
aws s3 ls s3://hello-floci
```

---

## 📁 Repository Structure

```
labs/
  01-setup.md              # Installation & first start
  02-s3.md                 # S3 buckets & objects
  03-sqs-dynamodb.md       # SQS queues + DynamoDB tables
  04-sns-fanout.md         # SNS topics & fan-out
  05-lambda.md             # Lambda deploy & invoke
  06-developer-workflow.md # Dev loop & CI integration
  07-floci-vs-others.md    # Comparison guide
scripts/
  00-env.sh                # Environment setup helper
  02-s3-demo.sh            # Live demo: S3
  03-sqs-dynamodb-demo.sh  # Live demo: SQS + DynamoDB
  04-sns-fanout-demo.sh    # Live demo: SNS fan-out
  05-lambda-demo.sh        # Live demo: Lambda
```

---

## 🔗 Resources

- 📖 [Floci Docs](https://floci.io/docs)
- 🐙 [GitHub: floci-io/floci](https://github.com/floci-io/floci)
- 💬 Slack: `#floci` in the Developer Kommunity workspace

