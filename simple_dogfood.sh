#!/bin/bash

set -e

echo "=== Simple GoldClaw Dogfood Test ==="
echo ""

# Configuration
export DATABASE_URL="postgresql://postgres:@localhost:5432/goldclaw"
export AGENT_SECRET="test-secret-for-dogfood"
export AGENT_ID="simple-test"
MOTHERSHIP_URL="http://localhost:4000"

# Clear old instructions
echo "Clearing old instructions..."
psql -U postgres -d goldclaw -c "DELETE FROM instructions WHERE agent_id='$AGENT_ID';"

# Kill any existing server
pkill -f "mix run" 2>/dev/null || true
sleep 2

# Start the server
echo "Starting GoldClaw server..."
cd /Users/speed/.openclaw/workspace
mix run --no-halt 2>&1 &
SERVER_PID=$!
echo "Server PID: $SERVER_PID"
sleep 6

# Test 1: Health Check
echo ""
echo "=== Test 1: Health Check ==="
HEALTH_RESPONSE=$(curl -s $MOTHERSHIP_URL/api/health)
echo "Response: $HEALTH_RESPONSE"

# Test 2: Register Agent via Heartbeat
echo ""
echo "=== Test 2: Send Heartbeat ==="
TIMESTAMP=$(date +%s)
NONCE=$(uuidgen | tr '[:upper:]' '[:lower:]')
HEARTBEAT_BODY='{
  "specversion": "1.0",
  "type": "com.cybernetic.agent.heartbeat",
  "source": "urn:ironclaw:agent:'$AGENT_ID'",
  "subject": "'$AGENT_ID'",
  "id": "evt-simple-001",
  "time": "2026-02-21T22:30:00Z",
  "datacontenttype": "application/json",
  "data": {
    "status": "online",
    "cpu_load": 0.45,
    "memory_mb": 512,
    "disk_gb": 80
  }
}'

MESSAGE="${TIMESTAMP}\n${NONCE}\n${HEARTBEAT_BODY}"
SIG=$(printf "%s" "$MESSAGE" | openssl dgst -sha256 -hmac "$AGENT_SECRET" -binary | xxd -p -c 256 | tr '[:lower:]' '[:upper:]')

HEARTBEAT_RESPONSE=$(curl -s -X POST $MOTHERSHIP_URL/api/signals \
  -H "Content-Type: application/json" \
  -H "X-Cybernetic-Timestamp: $TIMESTAMP" \
  -H "X-Cybernetic-Nonce: $NONCE" \
  -H "X-Cybernetic-Signature: $SIG" \
  -d "$HEARTBEAT_BODY")

echo "Response: $HEARTBEAT_RESPONSE"

# Test 3: Create and Fetch Instruction
echo ""
echo "=== Test 3: Create and Fetch Instruction ==="

# Create instruction directly in DB
psql -U postgres -d goldclaw -c "
  INSERT INTO instructions (id, instruction_id, agent_id, status, payload, created_at, updated_at)
  VALUES (
    gen_random_uuid(),
    'simple-instruction-001',
    '$AGENT_ID',
    'pending',
    '{\"action\":\"echo\",\"message\":\"Hello GoldClaw!\"}'::jsonb,
    NOW(),
    NOW()
  );
"

# Wait for queue
sleep 2

# Fetch with auth
TIMESTAMP=$(date +%s)
NONCE=$(uuidgen | tr '[:upper:]' '[:lower:]')
MESSAGE="${TIMESTAMP}\n${NONCE}\n"
SIG=$(printf "%s" "$MESSAGE" | openssl dgst -sha256 -hmac "$AGENT_SECRET" -binary | xxd -p -c 256 | tr '[:lower:]' '[:upper:]')

echo "Fetching instruction..."
FETCH_RESPONSE=$(curl -s -X GET $MOTHERSHIP_URL/api/instructions/$AGENT_ID \
  -H "X-Cybernetic-Timestamp: $TIMESTAMP" \
  -H "X-Cybernetic-Nonce: $NONCE" \
  -H "X-Cybernetic-Signature: $SIG")

echo "Fetch Response:"
echo "$FETCH_RESPONSE" | jq . 2>/dev/null || echo "$FETCH_RESPONSE"

echo ""
echo "=== Killing server ==="
kill $SERVER_PID 2>/dev/null
wait $SERVER_PID 2>/dev/null 2>/dev/null

echo ""
echo "=== Test Complete ==="
