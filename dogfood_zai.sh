#!/bin/bash

set -e

echo "=== GoldClaw Dogfood Test with z.ai ==="
echo ""

# Configuration
export DATABASE_URL="postgresql://postgres:@localhost:5432/goldclaw"
export AGENT_SECRET="test-secret-for-dogfood"
export AGENT_ID="dogfood-zai"
MOTHERSHIP_URL="http://localhost:4000"

# Kill any existing server
echo "Killing any existing GoldClaw server..."
pkill -f "mix run" 2>/dev/null || true
sleep 2

# Start the server
echo "Starting GoldClaw server..."
cd /Users/speed/.openclaw/workspace
mix run --no-halt &
SERVER_PID=$!
echo "Server PID: $SERVER_PID"
sleep 5

# Test 1: Health Check
echo ""
echo "=== Test 1: Health Check ==="
HEALTH_RESPONSE=$(curl -s $MOTHERSHIP_URL/api/health)
echo "Response: $HEALTH_RESPONSE"

# Test 2: Register Agent via Heartbeat
echo ""
echo "=== Test 2: Register Agent via Heartbeat ==="
TIMESTAMP=$(date +%s)
NONCE=$(uuidgen | tr '[:upper:]' '[:lower:]')
HEARTBEAT_BODY='{
  "specversion": "1.0",
  "type": "com.cybernetic.agent.heartbeat",
  "source": "urn:ironclaw:agent:'$AGENT_ID'",
  "subject": "'$AGENT_ID'",
  "id": "evt-001",
  "time": "2026-02-21T22:30:00Z",
  "datacontenttype": "application/json",
  "data": {
    "status": "online",
    "cpu_load": 0.45,
    "memory_mb": 512,
    "disk_gb": 80,
    "current_task": "dogfood_zai_test",
    "last_error": null
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
echo ""

# Test 3: Create Instruction (AI Query)
echo "=== Test 3: Create AI Query Instruction ==="
psql -U postgres -d goldclaw -c "
  INSERT INTO instructions (id, instruction_id, agent_id, status, payload, created_at, updated_at)
  VALUES (
    gen_random_uuid(),
    'zai-query-001',
    '$AGENT_ID',
    'pending',
    '{\"action\":\"ai_query\",\"query\":\"Explain GoldClaw architecture in 100 words\"}'::jsonb,
    NOW(),
    NOW()
  );
"

# Wait a moment for queue to be ready
sleep 2

# Test 4: Fetch Instruction
echo ""
echo "=== Test 4: Fetch Instruction (with auth) ==="
TIMESTAMP=$(date +%s)
NONCE=$(uuidgen | tr '[:upper:]' '[:lower:]')
MESSAGE="${TIMESTAMP}\n${NONCE}\n"
SIG=$(printf "%s" "$MESSAGE" | openssl dgst -sha256 -hmac "$AGENT_SECRET" -binary | xxd -p -c 256 | tr '[:lower:]' '[:upper:]')

FETCH_RESPONSE=$(curl -s -X GET $MOTHERSHIP_URL/api/instructions/$AGENT_ID \
  -H "X-Cybernetic-Timestamp: $TIMESTAMP" \
  -H "X-Cybernetic-Nonce: $NONCE" \
  -H "X-Cybernetic-Signature: $SIG")

echo "Fetch Response:"
echo "$FETCH_RESPONSE" | jq .
echo ""

# Test 5: Check Database
echo "=== Test 5: Check Database ==="
psql -U postgres -d goldclaw -c "
  SELECT instruction_id, agent_id, status, created_at
  FROM instructions
  WHERE agent_id='$AGENT_ID'
  ORDER BY created_at DESC
  LIMIT 5;
"

echo ""
echo "=== Killing server ==="
kill $SERVER_PID 2>/dev/null
wait $SERVER_PID 2>/dev/null

echo ""
echo "=== Dogfood Test Complete ==="
echo "All tests executed!"
echo ""
echo "Summary:"
echo "- Health check: $([ \"$HEALTH_RESPONSE\" = *healthy* ] && echo '✅ PASS' || echo '❌ FAIL')"
echo "- Heartbeat sent: $([ \"$HEARTBEAT_RESPONSE\" = *accepted* ] && echo '✅ PASS' || echo '❌ FAIL')"
echo "- Instruction created: ✅ PASS"
echo "- Instruction fetch: $([ \"$FETCH_RESPONSE\" = *instruction_id* ] && echo '✅ PASS' || echo '❌ FAIL')"
