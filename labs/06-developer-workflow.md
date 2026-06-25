# Lab 06 — Developer Workflow & CI

**Duration:** ~15 min  
**Goal:** Integrate Floci into a realistic developer loop and a CI pipeline using Testcontainers.

---

## Part A — The Local Developer Loop

```
Edit code → Run tests (Floci in Docker / Podman) → Fix → Repeat
              ↑ fast, no cloud, no cost
```

The goal is to **never need a real AWS account** during development or testing.

---

## Part B — Floci as a Compose Sidecar (Project Template)

The `compose.yaml` is the same regardless of runtime — only the command differs.

```yaml
# compose.yaml
services:
  app:
    build: .
    environment:
      AWS_ENDPOINT_URL: http://floci:4566
      AWS_DEFAULT_REGION: us-east-1
      AWS_ACCESS_KEY_ID: test
      AWS_SECRET_ACCESS_KEY: test
    depends_on:
      floci:
        condition: service_healthy

  floci:
    image: floci/floci:latest
    ports:
      - "4566:4566"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:4566/_floci/health"]
      interval: 5s
      timeout: 3s
      retries: 10
```

Start your full stack:

| Runtime | Command |
|---------|--------|
| Docker | `docker compose up` |
| Podman | `podman compose up` |

> 💡 **macOS + Podman:** ensure the Podman machine is running first: `podman machine start`  
> 💡 **Windows:** run these commands inside your **WSL2** terminal.

---

## Part C — Testcontainers (Unit / Integration Tests)

Floci has first-class Testcontainers support. Your tests spin up a fresh Floci instance per test suite — fully isolated, no shared state.

> ⚙️ **Set `DOCKER_HOST` before running tests** so Testcontainers finds your container runtime:
>
> | Platform | Runtime | Command |
> |----------|---------|--------|
> | macOS | Docker Desktop | *(no change needed — socket auto-detected)* |
> | macOS | Podman | `export DOCKER_HOST=$(podman machine inspect --format 'unix://{{.ConnectionInfo.PodmanSocket.Path}}')` |
> | Windows (WSL2) | Docker Desktop | `export DOCKER_HOST=unix:///var/run/docker.sock` |
> | Windows (WSL2) | Podman | `export DOCKER_HOST=unix:///run/user/$(id -u)/podman/podman.sock` |
>
> For **Podman rootless** on any platform, also set:  
> `export TESTCONTAINERS_RYUK_DISABLED=true` (Ryuk resource-reaper is not supported by rootless Podman).

### Node.js / TypeScript

Install:

```bash
npm install --save-dev @floci/testcontainers
```

Test:

```typescript
import { FlociContainer } from "@floci/testcontainers";
import { S3Client, CreateBucketCommand, ListBucketsCommand } from "@aws-sdk/client-s3";

describe("S3 integration", () => {
  let floci: FlociContainer;
  let s3: S3Client;

  beforeAll(async () => {
    floci = await new FlociContainer().start();

    s3 = new S3Client({
      endpoint: floci.getEndpoint(),
      region: floci.getRegion(),
      credentials: {
        accessKeyId: floci.getAccessKey(),
        secretAccessKey: floci.getSecretKey(),
      },
      forcePathStyle: true,
    });
  });

  afterAll(async () => {
    await floci.stop();
  });

  it("creates and lists a bucket", async () => {
    await s3.send(new CreateBucketCommand({ Bucket: "test-bucket" }));
    const { Buckets } = await s3.send(new ListBucketsCommand({}));
    expect(Buckets?.map(b => b.Name)).toContain("test-bucket");
  });
});
```

### Python

Install:

```bash
pip install testcontainers-floci boto3
```

Test:

```python
import boto3
from testcontainers_floci import FlociContainer

def test_s3_create_bucket():
    with FlociContainer() as floci:
        s3 = boto3.client(
            "s3",
            endpoint_url=floci.get_endpoint(),
            region_name=floci.get_region(),
            aws_access_key_id=floci.get_access_key(),
            aws_secret_access_key=floci.get_secret_key(),
        )
        s3.create_bucket(Bucket="test-bucket")
        buckets = [b["Name"] for b in s3.list_buckets()["Buckets"]]
        assert "test-bucket" in buckets
```

### Java (JUnit 5)

```xml
<!-- pom.xml -->
<dependency>
  <groupId>io.floci</groupId>
  <artifactId>testcontainers-floci</artifactId>
  <version>LATEST</version>
  <scope>test</scope>
</dependency>
```

```java
@Testcontainers
class S3IntegrationTest {

    @Container
    static FlociContainer floci = new FlociContainer();

    @Test
    void shouldCreateBucket() {
        S3Client s3 = S3Client.builder()
            .endpointOverride(URI.create(floci.getEndpoint()))
            .region(Region.of(floci.getRegion()))
            .credentialsProvider(StaticCredentialsProvider.create(
                AwsBasicCredentials.create(floci.getAccessKey(), floci.getSecretKey())))
            .forcePathStyle(true)
            .build();

        s3.createBucket(b -> b.bucket("my-bucket"));

        assertThat(s3.listBuckets().buckets())
            .anyMatch(b -> b.name().equals("my-bucket"));
    }
}
```

---

## Part D — CI Pipeline (GitHub Actions)

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    services:
      floci:
        image: floci/floci:latest
        ports:
          - 4566:4566
        options: >-
          --health-cmd "curl -f http://localhost:4566/_floci/health"
          --health-interval 5s
          --health-timeout 3s
          --health-retries 10

    steps:
      - uses: actions/checkout@v4

      - name: Set up Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 22

      - name: Install dependencies
        run: npm ci

      - name: Run tests
        env:
          AWS_ENDPOINT_URL: http://localhost:4566
          AWS_DEFAULT_REGION: us-east-1
          AWS_ACCESS_KEY_ID: test
          AWS_SECRET_ACCESS_KEY: test
        run: npm test
```

> 💡 No secrets needed. No AWS credentials. No IAM roles.  
> The same pipeline works for any team member and costs $0 to run.

---

## Part E — Initialization Hooks

Pre-seed Floci with resources on startup using init scripts (requires `floci/floci:latest-compat`):

```yaml
# compose.yaml
services:
  floci:
    image: floci/floci:latest-compat
    volumes:
      - ./init:/etc/localstack/init/ready.d:ro
```

```sh
# init/01-seed.sh
#!/bin/sh
set -eu
aws sqs create-queue --queue-name orders
aws s3 mb s3://app-bucket
aws ssm put-parameter --name /app/config --type String --value production
aws dynamodb create-table \
  --table-name Users \
  --attribute-definitions AttributeName=id,AttributeType=S \
  --key-schema AttributeName=id,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

Every time Floci starts, your environment is pre-wired and ready.

---

## Key Takeaways

| Practice | Benefit |
|----------|---------|
| Floci as Podman / Docker Compose sidecar | Full stack locally, zero cloud |
| Testcontainers per test suite | Isolated, repeatable, fast |
| GitHub Actions service container | CI with no AWS account/secrets |
| Init hooks | Pre-seeded environment every run |

---

➡️ Next: [Lab 07 — Floci vs. the World](./07-floci-vs-others.md)
