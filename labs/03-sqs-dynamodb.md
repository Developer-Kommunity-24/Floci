# Lab 03 — SQS + DynamoDB

**Duration:** ~20 min  
**Goal:** Create queues, send and receive messages, create tables, and work with items.

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

## Part A — SQS: Simple Queue Service

### Create a standard queue

```bash
aws sqs create-queue --queue-name orders
```

### List queues

```bash
aws sqs list-queues
```

### Send a message

```bash
aws sqs send-message \
  --queue-url $AWS_ENDPOINT_URL/000000000000/orders \
  --message-body '{"event":"order.placed","orderId":"ORD-001","amount":49.99}'
```

### Send a batch of messages

```bash
aws sqs send-message-batch \
  --queue-url $AWS_ENDPOINT_URL/000000000000/orders \
  --entries '[
    {"Id":"1","MessageBody":"{\"event\":\"order.placed\",\"orderId\":\"ORD-002\"}"},
    {"Id":"2","MessageBody":"{\"event\":\"order.placed\",\"orderId\":\"ORD-003\"}"},
    {"Id":"3","MessageBody":"{\"event\":\"order.cancelled\",\"orderId\":\"ORD-001\"}"}
  ]'
```

### Receive messages

```bash
aws sqs receive-message \
  --queue-url $AWS_ENDPOINT_URL/000000000000/orders \
  --max-number-of-messages 5 | jq .
```

### Delete a message (acknowledge it)

```bash
# Capture the receipt handle from the receive-message response
RECEIPT=$(aws sqs receive-message \
  --queue-url $AWS_ENDPOINT_URL/000000000000/orders \
  --query 'Messages[0].ReceiptHandle' --output text)

aws sqs delete-message \
  --queue-url $AWS_ENDPOINT_URL/000000000000/orders \
  --receipt-handle "$RECEIPT"
```

### Get queue attributes (depth, etc.)

```bash
aws sqs get-queue-attributes \
  --queue-url $AWS_ENDPOINT_URL/000000000000/orders \
  --attribute-names All | jq .
```

### Create a FIFO queue

```bash
aws sqs create-queue \
  --queue-name payments.fifo \
  --attributes FifoQueue=true,ContentBasedDeduplication=true
```

---

## Part B — DynamoDB

### Create a table

```bash
aws dynamodb create-table \
  --table-name Users \
  --attribute-definitions \
    AttributeName=id,AttributeType=S \
  --key-schema \
    AttributeName=id,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

### List tables

```bash
aws dynamodb list-tables | jq .
```

### Put items

```bash
aws dynamodb put-item \
  --table-name Users \
  --item '{
    "id":    {"S": "user-001"},
    "name":  {"S": "Alice"},
    "email": {"S": "alice@example.com"},
    "plan":  {"S": "pro"}
  }'

aws dynamodb put-item \
  --table-name Users \
  --item '{
    "id":    {"S": "user-002"},
    "name":  {"S": "Bob"},
    "email": {"S": "bob@example.com"},
    "plan":  {"S": "free"}
  }'
```

### Get an item by key

```bash
aws dynamodb get-item \
  --table-name Users \
  --key '{"id": {"S": "user-001"}}' | jq .
```

### Scan the whole table

```bash
aws dynamodb scan --table-name Users | jq .
```

### Query with a filter

```bash
aws dynamodb scan \
  --table-name Users \
  --filter-expression "plan = :p" \
  --expression-attribute-values '{":p":{"S":"pro"}}' | jq .
```

### Update an item

```bash
aws dynamodb update-item \
  --table-name Users \
  --key '{"id": {"S": "user-002"}}' \
  --update-expression "SET plan = :p" \
  --expression-attribute-values '{":p":{"S":"pro"}}'
```

### Delete an item

```bash
aws dynamodb delete-item \
  --table-name Users \
  --key '{"id": {"S": "user-002"}}'
```

---

## Part C — Putting It Together

Simulate an event-driven flow: a new user signs up → write to DynamoDB → push a notification to SQS.

```bash
# Write user
aws dynamodb put-item \
  --table-name Users \
  --item '{"id":{"S":"user-003"},"name":{"S":"Carol"},"plan":{"S":"free"}}'

# Push signup event to queue
aws sqs send-message \
  --queue-url $AWS_ENDPOINT_URL/000000000000/orders \
  --message-body '{"event":"user.registered","userId":"user-003"}'

# Consume it
aws sqs receive-message \
  --queue-url $AWS_ENDPOINT_URL/000000000000/orders | jq .
```

---

## Challenge 🏆

> 1. Create a DynamoDB table called `Products` with a partition key `sku` (String)
> 2. Insert 3 products with at least `name`, `price`, and `category` fields
> 3. Scan for only products in category `electronics`
> 4. Send a `product.created` SQS message for each inserted product

---

➡️ Next: [Lab 04 — SNS Fan-out](./04-sns-fanout.md)
