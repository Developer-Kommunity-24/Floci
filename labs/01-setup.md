# Lab 01 — Setup & First Start

**Duration:** ~15 min  
**Goal:** Install Floci, start the emulator, and confirm it's working.

---

## Step 0 — Choose Your Platform & Runtime

Pick the column that matches your machine. You only need to follow **one** path.

|  | 🍎 macOS + Docker | 🍎 macOS + Podman | 🪟 Windows + Docker | 🪟 Windows + Podman |
|--|:-----------------:|:-----------------:|:-------------------:|:-------------------:|
| Supported | ✅ | ✅ | ✅ | ✅ |
| Shell used | zsh / bash | zsh / bash | WSL2 (bash) | WSL2 (bash) |
| Compose cmd | `docker compose` | `podman compose` | `docker compose` | `podman compose` |

> 🪟 **Windows users:** all terminal commands in this workshop run inside a **WSL2** shell.  
> Open it with: `wsl` in PowerShell, or launch "Ubuntu" from the Start menu.  
> Enable WSL2 first if needed: run `wsl --install` in PowerShell (Admin), then reboot.

---

## Step 1 — Install Prerequisites

### 🍎 macOS — Docker

```bash
# Docker Desktop
brew install --cask docker
# Open Docker Desktop once to complete setup, then verify:
docker --version

# AWS CLI + jq
brew install awscli jq

# Pull the Floci image
docker pull floci/floci:latest
```

---

### 🍎 macOS — Podman

```bash
# Podman + Podman Compose
brew install podman podman-compose

# Initialise and start the Podman VM
podman machine init
podman machine start

# Verify
podman --version

# AWS CLI + jq
brew install awscli jq

# Pull the Floci image
podman pull floci/floci:latest
```

---

### 🪟 Windows — Docker

> Run all of the following inside your **WSL2** terminal.

1. Install [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/).  
   In Docker Desktop → Settings → **Resources → WSL Integration** → enable your distro.

2. Inside WSL2:

```bash
# Verify Docker is visible inside WSL2
docker --version

# AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip /tmp/awscliv2.zip -d /tmp && sudo /tmp/aws/install

# jq
sudo apt-get install -y jq

# Pull the Floci image
docker pull floci/floci:latest
```

---

### 🪟 Windows — Podman

> Run all of the following inside your **WSL2** terminal.

1. Install [Podman Desktop](https://podman-desktop.io/) on Windows.  
   Or via winget (PowerShell Admin): `winget install RedHat.Podman RedHat.PodmanDesktop`

2. Inside WSL2:

```bash
# Install Podman in WSL2
sudo apt-get update && sudo apt-get install -y podman podman-compose

# Verify
podman --version

# AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip /tmp/awscliv2.zip -d /tmp && sudo /tmp/aws/install

# jq
sudo apt-get install -y jq

# Pull the Floci image
podman pull floci/floci:latest
```

---

### ✅ Verify All Tools

Run this on any platform:

```bash
aws --version
jq --version
docker images floci/floci   # or: podman images floci/floci
```

---

## Step 2 — Start Floci

### Option A — Docker (quick run)

```bash
docker run -d --name floci \
  -p 4566:4566 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  floci/floci:latest
```

---

### Option B — Docker Compose

1. Create a `compose.yaml` file in your project folder:

```bash
mkdir -p ~/floci-workshop && cd ~/floci-workshop
```

2. Paste the following into `compose.yaml`:

```yaml
services:
  floci:
    image: floci/floci:latest
    container_name: floci
    ports:
      - "4566:4566"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./data:/app/data
    environment:
      FLOCI_HOSTNAME: localhost
    restart: unless-stopped
```

3. Start Floci:

```bash
docker compose up -d
```

---

### Option C — Podman Compose

1. Create a `compose.yaml` file in your project folder:

```bash
mkdir -p ~/floci-workshop && cd ~/floci-workshop
```

2. Paste the following into `compose.yaml`:

```yaml
services:
  floci:
    image: floci/floci:latest
    container_name: floci
    ports:
      - "4566:4566"
    volumes:
      - ./data:/app/data
    environment:
      FLOCI_HOSTNAME: localhost
    restart: unless-stopped
```

3. Start Floci:

```bash
podman compose up -d
```

---

### Option D — Podman CLI (rootless, no compose)

```bash
podman network create floci-net

podman run -d --name floci \
  --network floci-net \
  -p 4566:4566 \
  -v /run/user/$(id -u)/podman/podman.sock:/var/run/docker.sock:Z \
  -e FLOCI_SERVICES_LAMBDA_DOCKER_NETWORK=floci-net \
  -e FLOCI_HOSTNAME=floci \
  floci/floci
```

> ✅ Floci is ready when you see it listening on `http://localhost:4566`.

---

## Step 3 — Point Your AWS Tools at Floci

### macOS / WSL2 (bash / zsh)

```bash
export AWS_ENDPOINT_URL=http://localhost:4566
export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_PAGER=""
```

> 💡 Add these to your `~/.zshrc` or `~/.bashrc` so they persist across terminal sessions during the workshop.

### Windows — PowerShell (native, without WSL2)

```powershell
$env:AWS_ENDPOINT_URL      = "http://localhost:4566"
$env:AWS_DEFAULT_REGION    = "us-east-1"
$env:AWS_ACCESS_KEY_ID     = "test"
$env:AWS_SECRET_ACCESS_KEY = "test"
```

> 💡 Floci accepts **any** value for key/secret — no real AWS credentials required.

---

## Step 4 — Verify the Emulator is Healthy

```bash
curl -s http://localhost:4566/_floci/health | jq .
```

Expected (truncated — you'll see all 65 services):

```json
{
  "version": "1.5.27",
  "original_edition": "floci-always-free",
  "edition": "community",
  "services": {
    "s3": "running",
    "sqs": "running",
    "dynamodb": "running",
    "sns": "running",
    "lambda": "running",
    "apigateway": "running",
    "iam": "running",
    "kinesis": "running",
    "kms": "running",
    "secretsmanager": "running",
    "cloudformation": "running",
    "bedrock-runtime": "running",
    "... (65 services total)": "running"
  }
}
```

> 💡 All 65 services start automatically — no config needed. Notice there's no `"status": "UP"` field; if you get a valid JSON response with services listed, Floci is healthy.

Open the Floci UI in your browser: **http://localhost:4566**

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
| `Cannot connect to Docker daemon` | Open Docker Desktop (macOS) or run `sudo systemctl start docker` (Linux/WSL2) |
| Port 4566 already in use | `lsof -i :4566` (macOS/Linux) or `netstat -ano \| findstr 4566` (Windows) then kill the process |
| Podman machine not running (macOS) | `podman machine start` |
| Docker not visible in WSL2 | Docker Desktop → Settings → WSL Integration → enable your distro |
| `connection refused` on health check | Wait ~10s and retry; Floci container may still be starting |
| Podman rootless: `permission denied` on socket | Add `:Z` SELinux label to the volume mount |

