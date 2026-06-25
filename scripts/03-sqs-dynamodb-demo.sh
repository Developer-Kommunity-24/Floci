#!/usr/bin/env zsh
# scripts/03-sqs-dynamodb-demo.sh
# Live demo: SQS queues + DynamoDB tables

set -euo pipefail
source "$(dirname "$0")/00-env.sh"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📬  SQS + 🗄️  DynamoDB DEMO"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── SQS ──────────────────────────────────────
echo ""
echo "[ SQS ]"

echo "▶ Creating queue: orders"
aws sqs create-queue --queue-name orders

QUEUE_URL="$AWS_ENDPOINT_URL/000000000000/orders"

echo ""
echo "▶ Sending 3 messages..."
aws sqs send-message --queue-url "$QUEUE_URL" \
  --message-body '{"event":"order.placed","orderId":"ORD-001","amount":29.99}'

aws sqs send-message --queue-url "$QUEUE_URL" \
  --message-body '{"event":"order.placed","orderId":"ORD-002","amount":59.99}'

aws sqs send-message --queue-url "$QUEUE_URL" \
  --message-body '{"event":"order.cancelled","orderId":"ORD-001"}'

echo ""
echo "▶ Queue depth:"
aws sqs get-queue-attributes \
  --queue-url "$QUEUE_URL" \
  --attribute-names ApproximateNumberOfMessages \
  | jq '.Attributes.ApproximateNumberOfMessages'

echo ""
echo "▶ Receiving messages:"
aws sqs receive-message \
  --queue-url "$QUEUE_URL" \
  --max-number-of-messages 3 \
  | jq '.Messages[] | {Body: (.Body | fromjson)}'

# ── DynamoDB ─────────────────────────────────
echo ""
echo "[ DynamoDB ]"

echo "▶ Creating table: Products"
aws dynamodb create-table \
  --table-name Products \
  --attribute-definitions AttributeName=sku,AttributeType=S \
  --key-schema AttributeName=sku,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST

echo ""
echo "▶ Inserting items..."
aws dynamodb put-item --table-name Products --item \
  '{"sku":{"S":"SKU-001"},"name":{"S":"Wireless Mouse"},"price":{"N":"29.99"},"category":{"S":"electronics"}}'

aws dynamodb put-item --table-name Products --item \
  '{"sku":{"S":"SKU-002"},"name":{"S":"USB-C Hub"},"price":{"N":"49.99"},"category":{"S":"electronics"}}'

aws dynamodb put-item --table-name Products --item \
  '{"sku":{"S":"SKU-003"},"name":{"S":"Standing Desk"},"price":{"N":"399.00"},"category":{"S":"furniture"}}'

echo ""
echo "▶ Get item by key (SKU-001):"
aws dynamodb get-item \
  --table-name Products \
  --key '{"sku":{"S":"SKU-001"}}' \
  | jq '.Item | {sku: .sku.S, name: .name.S, price: .price.N}'

echo ""
echo "▶ Scan for electronics only:"
aws dynamodb scan \
  --table-name Products \
  --filter-expression "category = :c" \
  --expression-attribute-values '{":c":{"S":"electronics"}}' \
  | jq '.Items[] | {sku: .sku.S, name: .name.S}'

# ── Cleanup ───────────────────────────────────
echo ""
echo "▶ Cleaning up..."
aws sqs delete-queue --queue-url "$QUEUE_URL"
aws dynamodb delete-table --table-name Products

echo ""
echo "✅  SQS + DynamoDB demo complete!"
