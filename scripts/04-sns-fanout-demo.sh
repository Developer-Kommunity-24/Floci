#!/usr/bin/env zsh
# scripts/04-sns-fanout-demo.sh
# Live demo: SNS topics + SQS fan-out

set -euo pipefail
source "$(dirname "$0")/00-env.sh"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📣  SNS FAN-OUT DEMO"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 1. Create SNS topic
echo ""
echo "▶ Creating SNS topic: notifications"
TOPIC_ARN=$(aws sns create-topic --name notifications --query TopicArn --output text)
echo "   Topic ARN: $TOPIC_ARN"

# 2. Create subscriber queues
echo ""
echo "▶ Creating subscriber queues..."
aws sqs create-queue --queue-name email-service    > /dev/null
aws sqs create-queue --queue-name analytics-service > /dev/null
aws sqs create-queue --queue-name audit-service    > /dev/null
echo "   email-service, analytics-service, audit-service ✅"

# 3. Get queue ARNs
EMAIL_ARN=$(aws sqs get-queue-attributes \
  --queue-url "$AWS_ENDPOINT_URL/000000000000/email-service" \
  --attribute-names QueueArn --query Attributes.QueueArn --output text)

ANALYTICS_ARN=$(aws sqs get-queue-attributes \
  --queue-url "$AWS_ENDPOINT_URL/000000000000/analytics-service" \
  --attribute-names QueueArn --query Attributes.QueueArn --output text)

AUDIT_ARN=$(aws sqs get-queue-attributes \
  --queue-url "$AWS_ENDPOINT_URL/000000000000/audit-service" \
  --attribute-names QueueArn --query Attributes.QueueArn --output text)

# 4. Subscribe queues
echo ""
echo "▶ Subscribing all queues to the topic..."
aws sns subscribe --topic-arn "$TOPIC_ARN" --protocol sqs --notification-endpoint "$EMAIL_ARN"     > /dev/null
aws sns subscribe --topic-arn "$TOPIC_ARN" --protocol sqs --notification-endpoint "$ANALYTICS_ARN" > /dev/null
aws sns subscribe --topic-arn "$TOPIC_ARN" --protocol sqs --notification-endpoint "$AUDIT_ARN"     > /dev/null

echo "   Subscriptions:"
aws sns list-subscriptions-by-topic --topic-arn "$TOPIC_ARN" \
  | jq '.Subscriptions[] | {queue: .Endpoint, protocol: .Protocol}'

# 5. Publish a message
echo ""
echo "▶ Publishing message: user.registered"
aws sns publish \
  --topic-arn "$TOPIC_ARN" \
  --message '{"event":"user.registered","userId":"user-042","plan":"pro"}' \
  --subject "User Registered" \
  | jq '{MessageId}'

# 6. Verify fan-out
echo ""
echo "▶ Checking all subscriber queues..."

for QUEUE in email-service analytics-service audit-service; do
  echo ""
  echo "  ── $QUEUE ──"
  aws sqs receive-message \
    --queue-url "$AWS_ENDPOINT_URL/000000000000/$QUEUE" \
    | jq '.Messages[0].Body | fromjson | {Subject, Message: (.Message | fromjson)}'
done

# 7. Cleanup
echo ""
echo "▶ Cleaning up..."
aws sns delete-topic --topic-arn "$TOPIC_ARN"
for QUEUE in email-service analytics-service audit-service; do
  aws sqs delete-queue --queue-url "$AWS_ENDPOINT_URL/000000000000/$QUEUE"
done

echo ""
echo '✅  SNS fan-out demo complete!'
