# Lab 04 — SNS Fan-out

**Duration:** ~15 min  
**Goal:** Create an SNS topic, subscribe multiple SQS queues to it, publish a message, and verify all subscribers received it.

---

## Prerequisites

```bash
export AWS_ENDPOINT_URL=http://localhost:4566
export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
```

> 💡 Already set from Lab 01? Just verify: `echo $AWS_ENDPOINT_URL`

---

## The Pattern

```
Publisher
    │
    ▼
 SNS Topic (notifications)
    ├──► SQS Queue (email-service)
    ├──► SQS Queue (analytics-service)
    └──► SQS Queue (audit-service)
```

One publish → all three queues receive the message automatically.

---

## Part A — Create the Topic

```bash
TOPIC_ARN=$(aws sns create-topic \
  --name notifications \
  --query TopicArn --output text)

echo "Topic ARN: $TOPIC_ARN"
```

### List topics

```bash
aws sns list-topics | jq .
```

---

## Part B — Create Subscriber Queues

```bash
aws sqs create-queue --queue-name email-service
aws sqs create-queue --queue-name analytics-service
aws sqs create-queue --queue-name audit-service
```

Get their ARNs:

```bash
EMAIL_ARN=$(aws sqs get-queue-attributes \
  --queue-url $AWS_ENDPOINT_URL/000000000000/email-service \
  --attribute-names QueueArn \
  --query Attributes.QueueArn --output text)

ANALYTICS_ARN=$(aws sqs get-queue-attributes \
  --queue-url $AWS_ENDPOINT_URL/000000000000/analytics-service \
  --attribute-names QueueArn \
  --query Attributes.QueueArn --output text)

AUDIT_ARN=$(aws sqs get-queue-attributes \
  --queue-url $AWS_ENDPOINT_URL/000000000000/audit-service \
  --attribute-names QueueArn \
  --query Attributes.QueueArn --output text)

echo "Email:     $EMAIL_ARN"
echo "Analytics: $ANALYTICS_ARN"
echo "Audit:     $AUDIT_ARN"
```

---

## Part C — Subscribe Queues to the Topic

```bash
aws sns subscribe \
  --topic-arn $TOPIC_ARN \
  --protocol sqs \
  --notification-endpoint $EMAIL_ARN

aws sns subscribe \
  --topic-arn $TOPIC_ARN \
  --protocol sqs \
  --notification-endpoint $ANALYTICS_ARN

aws sns subscribe \
  --topic-arn $TOPIC_ARN \
  --protocol sqs \
  --notification-endpoint $AUDIT_ARN
```

### Verify subscriptions

```bash
aws sns list-subscriptions-by-topic --topic-arn $TOPIC_ARN | jq .
```

---

## Part D — Publish a Message

```bash
aws sns publish \
  --topic-arn $TOPIC_ARN \
  --message '{"event":"user.registered","userId":"user-042","plan":"pro"}' \
  --subject "User Registered"
```

---

## Part E — Verify Fan-out

All three queues should now have the message:

```bash
echo "=== email-service ===" && \
aws sqs receive-message \
  --queue-url $AWS_ENDPOINT_URL/000000000000/email-service | jq .

echo "=== analytics-service ===" && \
aws sqs receive-message \
  --queue-url $AWS_ENDPOINT_URL/000000000000/analytics-service | jq .

echo "=== audit-service ===" && \
aws sqs receive-message \
  --queue-url $AWS_ENDPOINT_URL/000000000000/audit-service | jq .
```

> 💡 The message body each queue receives is a JSON envelope from SNS. The original message is inside the `Message` field.

---

## Part F — Message Filtering (Bonus)

Subscribe with a filter policy so only certain messages reach a queue:

```bash
# Create a VIP-only queue
aws sqs create-queue --queue-name vip-service

VIP_ARN=$(aws sqs get-queue-attributes \
  --queue-url $AWS_ENDPOINT_URL/000000000000/vip-service \
  --attribute-names QueueArn \
  --query Attributes.QueueArn --output text)

# Subscribe with filter: only receive messages where plan = "pro"
aws sns subscribe \
  --topic-arn $TOPIC_ARN \
  --protocol sqs \
  --notification-endpoint $VIP_ARN \
  --attributes '{"FilterPolicy":"{\"plan\":[\"pro\"]}"}'

# Publish a "free" plan message — vip-service should NOT receive it
aws sns publish \
  --topic-arn $TOPIC_ARN \
  --message '{"event":"user.registered","userId":"user-043","plan":"free"}' \
  --message-attributes '{"plan":{"DataType":"String","StringValue":"free"}}'

# Publish a "pro" plan message — vip-service SHOULD receive it
aws sns publish \
  --topic-arn $TOPIC_ARN \
  --message '{"event":"user.registered","userId":"user-044","plan":"pro"}' \
  --message-attributes '{"plan":{"DataType":"String","StringValue":"pro"}}'

# Check — vip-service should have exactly 1 message
aws sqs receive-message \
  --queue-url $AWS_ENDPOINT_URL/000000000000/vip-service | jq .
```

---

## Challenge 🏆

> Build a mini notification system:
> 1. Create a topic called `orders`
> 2. Subscribe two queues: `fulfillment` and `billing`
> 3. Publish 3 order events: 2 with `status=placed`, 1 with `status=cancelled`
> 4. Add a filtered subscriber `refunds` that only receives `status=cancelled`
> 5. Verify all queues received the correct messages

---

➡️ Next: [Lab 05 — Lambda](./05-lambda.md)
