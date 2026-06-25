#!/usr/bin/env zsh
# scripts/05-lambda-demo.sh
# Live demo: Write, deploy, and invoke a Lambda function

set -euo pipefail
source "$(dirname "$0")/00-env.sh"

WORK_DIR=$(mktemp -d)
FUNCTION_NAME="hello-floci-demo"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚡  LAMBDA DEMO"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 1. Write the function
echo ""
echo "▶ Writing Lambda handler (Node.js)..."
cat > "$WORK_DIR/index.mjs" << 'EOF'
export const handler = async (event) => {
  console.log("Event:", JSON.stringify(event, null, 2));

  const name      = event.name ?? "World";
  const timestamp = new Date().toISOString();
  const region    = process.env.AWS_DEFAULT_REGION ?? "unknown";

  return {
    statusCode: 200,
    body: JSON.stringify({ message: `Hello, ${name}!`, timestamp, region }),
  };
};
EOF

cat "$WORK_DIR/index.mjs"

# 2. Package
echo ""
echo "▶ Packaging into function.zip..."
(cd "$WORK_DIR" && zip function.zip index.mjs > /dev/null)
ls -lh "$WORK_DIR/function.zip"

# 3. Deploy
echo ""
echo "▶ Deploying function: $FUNCTION_NAME"
aws lambda create-function \
  --function-name "$FUNCTION_NAME" \
  --runtime nodejs22.x \
  --role arn:aws:iam::000000000000:role/lambda-role \
  --handler index.handler \
  --zip-file "fileb://$WORK_DIR/function.zip" \
  | jq '{FunctionName, Runtime, Handler, State}'

# Wait for it to be active
echo "   Waiting for function to be active..."
aws lambda wait function-active --function-name "$FUNCTION_NAME"

# 4. Invoke synchronously
echo ""
echo "▶ Invoking synchronously with payload {\"name\":\"Developer Kommunity\"}..."
aws lambda invoke \
  --function-name "$FUNCTION_NAME" \
  --payload '{"name":"Developer Kommunity"}' \
  --cli-binary-format raw-in-base64-out \
  "$WORK_DIR/response.json" | jq '{StatusCode}'

echo "   Response:"
cat "$WORK_DIR/response.json" | jq '.body | fromjson'

# 5. Invoke with no payload
echo ""
echo "▶ Invoking with no payload (uses default name)..."
aws lambda invoke \
  --function-name "$FUNCTION_NAME" \
  --cli-binary-format raw-in-base64-out \
  "$WORK_DIR/response2.json" > /dev/null

cat "$WORK_DIR/response2.json" | jq '.body | fromjson'

# 6. Update function code
echo ""
echo "▶ Updating function to v2..."
cat > "$WORK_DIR/index.mjs" << 'EOF'
export const handler = async (event) => {
  const name      = event.name ?? "World";
  const timestamp = new Date().toISOString();
  const region    = process.env.AWS_DEFAULT_REGION ?? "unknown";

  return {
    statusCode: 200,
    body: JSON.stringify({ message: `Hello, ${name}!`, timestamp, region, version: "v2" }),
  };
};
EOF
(cd "$WORK_DIR" && zip -f function.zip index.mjs > /dev/null)

aws lambda update-function-code \
  --function-name "$FUNCTION_NAME" \
  --zip-file "fileb://$WORK_DIR/function.zip" | jq '{LastModified}'

aws lambda wait function-updated --function-name "$FUNCTION_NAME"

echo ""
echo "▶ Invoking v2..."
aws lambda invoke \
  --function-name "$FUNCTION_NAME" \
  --payload '{"name":"v2 Invoke"}' \
  --cli-binary-format raw-in-base64-out \
  "$WORK_DIR/response3.json" > /dev/null

cat "$WORK_DIR/response3.json" | jq '.body | fromjson'

# 7. Cleanup
echo ""
echo "▶ Cleaning up..."
aws lambda delete-function --function-name "$FUNCTION_NAME"
rm -rf "$WORK_DIR"

echo ""
echo "✅  Lambda demo complete!"
