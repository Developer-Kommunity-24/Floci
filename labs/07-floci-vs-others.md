# Lab 07 — Floci vs. the World

**Duration:** ~10 min  
**Goal:** Understand where Floci fits in the ecosystem and when to use each approach.

---

## The Landscape

When building cloud-native apps, you have four main options for testing cloud dependencies:

```
┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│    Mocks /   │  │    Floci     │  │  LocalStack  │  │  Real Cloud  │
│    Stubs     │  │  (this lab!) │  │              │  │  (AWS / GCP) │
└──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘
   Fastest             Fast              Fast              Slowest
   Cheapest            Free            Free / Paid         Costs money
   Least real         Very real        Very real          Most real
```

---

## Detailed Comparison

| Dimension | Mocks / Stubs | Floci | LocalStack | Real Cloud |
|-----------|:---:|:---:|:---:|:---:|
| **Setup time** | Seconds | Seconds | Seconds | Minutes–hours |
| **Cost** | Free | Free | Free / Pro (~$35/mo) | Pay per use |
| **No cloud account needed** | ✅ | ✅ | ✅ | ❌ |
| **AWS API fidelity** | ❌ Low | ✅ High | ✅ High | ✅ Full |
| **Services count** | Your choice | 59 services | 80+ services | All of AWS |
| **IAM / policies** | ❌ | Optional | Pro only | ✅ |
| **Lambda execution** | ❌ | ✅ Docker | ✅ Docker | ✅ Real |
| **Persistence** | ❌ | ✅ Configurable | ✅ Pro only | ✅ |
| **Works offline** | ✅ | ✅ | ✅ | ❌ |
| **CI-friendly** | ✅ | ✅ | ✅ | ⚠️ Credentials needed |
| **Testcontainers support** | ✅ (mock libs) | ✅ Native | ✅ Native | ❌ |
| **Migrate from LocalStack** | N/A | ✅ One-line image swap | — | N/A |

---

## When to Use Each

### ✅ Use Mocks / Stubs when…
- You want **pure unit tests** for business logic
- You need **maximum speed** (no Docker startup)
- The cloud service is not the thing being tested

```python
# Example: mock S3 in a unit test
from unittest.mock import MagicMock
s3 = MagicMock()
s3.get_object.return_value = {"Body": BytesIO(b"data")}
```

---

### ✅ Use Floci when…
- You want **realistic integration tests** without any cloud account
- You need **zero-config local dev** for the team
- You're **migrating from LocalStack** and want a free, drop-in alternative
- You need **59 AWS services** all running instantly, no config required
- CI pipelines must work with **no AWS secrets**

```bash
# Swap from LocalStack → Floci in one line:
# Before:  image: localstack/localstack
# After:   image: floci/floci:latest
```

---

### ✅ Use LocalStack when…
- You need services Floci doesn't yet cover
- You already have heavy LocalStack-specific tooling invested
- You need Pro features like IAM enforcement or persistence (paid tier)

> 💡 Floci is **source-compatible** with LocalStack. The same `AWS_ENDPOINT_URL=http://localhost:4566` convention works for both.

---

### ✅ Use Real Cloud when…
- Running **production traffic**
- Doing **final pre-production staging** tests
- Testing features requiring true AWS global infrastructure (CloudFront edges, multi-region, etc.)
- Verifying IAM policies with real credentials before deployment

---

## Migrating from LocalStack to Floci

It's a one-line Docker image swap:

```yaml
# Before
image: localstack/localstack

# After — standard
image: floci/floci:latest

# After — if your init scripts need AWS CLI or boto3
image: floci/floci:latest-compat
```

LocalStack environment variables are **automatically translated** by Floci — no renaming required:

| LocalStack Variable | Floci Equivalent | Notes |
|---------------------|-----------------|-------|
| `LOCALSTACK_HOST` | `FLOCI_HOSTNAME` | Auto-translated |
| `PERSISTENCE=1` | `FLOCI_STORAGE_MODE=persistent` | Auto-translated |
| `EDGE_PORT` | `FLOCI_PORT` | Auto-translated |
| `DEBUG=1` | `QUARKUS_LOG_LEVEL=DEBUG` | Auto-translated |
| `SERVICES=s3,sqs` | _(not needed)_ | Floci starts all 59 services instantly |
| `LAMBDA_EXECUTOR` | _(not needed)_ | Always Docker in Floci |

---

## The Decision Tree

```
Are you writing a unit test for business logic?
  └─ YES → Use mocks/stubs

Do you need real AWS API behaviour?
  └─ YES
      Is it production or final staging?
        └─ YES → Real Cloud
        └─ NO
            Do you need a specific service not in Floci?
              └─ YES → LocalStack
              └─ NO  → Floci ✅
```

---

## Summary

> **Floci is the best choice for the 80% of your development and testing cycle that happens before production.** It gives you real AWS API behaviour, 59 services, zero cost, and zero cloud account setup — making it ideal for every developer on the team, regardless of whether they have cloud credentials.

---

🎉 **You've completed the workshop!**  
Head back to the [README](../README.md) for resources and next steps.
