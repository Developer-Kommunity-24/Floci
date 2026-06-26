#!/usr/bin/env zsh
# scripts/02-s3-demo.sh
# Live demo: S3 buckets and objects

set -euo pipefail
source "$(dirname "$0")/00-env.sh"

BUCKET="workshop-demo-$(date +%s)"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦  S3 DEMO"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 1. Create a bucket
echo ""
echo "▶ Creating bucket: $BUCKET"
aws s3 mb "s3://$BUCKET"

# 2. Upload objects
echo ""
echo "▶ Uploading objects..."
echo 'hello, floci!' | aws s3 cp - "s3://$BUCKET/hello.txt"

echo '{"event":"order.placed","orderId":"ORD-001","amount":49.99}' > /tmp/event.json
aws s3 cp /tmp/event.json "s3://$BUCKET/events/order.json"

mkdir -p /tmp/sample-data
echo "row1,alice,pro"   > /tmp/sample-data/users1.csv
echo "row2,bob,free"    > /tmp/sample-data/users2.csv
aws s3 cp /tmp/sample-data/ "s3://$BUCKET/data/" --recursive

# 3. List objects
echo ""
echo "▶ Listing all objects in bucket:"
aws s3 ls "s3://$BUCKET" --recursive

# 4. Download and verify
echo ""
echo "▶ Downloading hello.txt and printing contents:"
aws s3 cp "s3://$BUCKET/hello.txt" /tmp/hello-downloaded.txt
cat /tmp/hello-downloaded.txt

# 5. Get object metadata
echo ""
echo "▶ Object metadata for events/order.json:"
aws s3api head-object --bucket "$BUCKET" --key events/order.json | jq '{ContentLength, ContentType, LastModified}'

# 6. Presigned URL
echo ""
echo "▶ Generating presigned URL (valid 60s):"
aws s3 presign "s3://$BUCKET/hello.txt" --expires-in 60

# 7. Cleanup
echo ""
echo "▶ Cleaning up..."
aws s3 rm "s3://$BUCKET" --recursive
aws s3 rb "s3://$BUCKET"

echo ""
echo '✅  S3 demo complete!'
