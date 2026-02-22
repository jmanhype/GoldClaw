# Dogfood Testing Guide

This guide walks through deploying and testing GoldClaw end-to-end.

## Prerequisites

1. **Fly.io CLI** (for deployment)
   ```bash
   curl -L https://fly.io/install.sh | sh
   ```

2. **PostgreSQL database** (Fly.io can provision one)

3. **IronClaw CLI** (for edge agent testing) - *Note: This is a fictional tool for spec testing. Replace with actual IronClaw CLI when available.*

## Deployment Steps

### 1. Deploy to Fly.io

```bash
cd /Users/speed/.openclaw/workspace/GoldClaw  # or wherever you cloned

# Login to Fly.io
flyctl auth login

# Launch the app (provisions app + DB)
fly launch

# Set up PostgreSQL
flyctl postgres create --name goldclaw-db

# Get database URL
flyctl postgres connect -a goldclaw-db -d postgres

# Set DATABASE_URL environment variable
flyctl secrets set DATABASE_URL=postgresql://user:pass@goldclaw-db.internal/goldclaw

# Set AGENT_SECRET (generate a secure random string)
flyctl secrets set AGENT_SECRET=$(openssl rand -base64 32)

# Deploy
fly deploy
```

### 2. Run Database Migrations

```bash
# Connect to running app
flyctl ssh console

# Run migrations
mix ecto.migrate

# Exit console
exit
```

### 3. Verify Deployment

```bash
# Check app health
curl https://goldclaw-mothership.fly.dev/api/health

# Should return:
# {"status":"healthy","version":"3.2.0"}
```

## Dogfood Test Scenarios

### Test 1: Heartbeat Signal (Edge → Cloud)

```bash
# Generate agent credentials
AGENT_ID="agent-test-001"
AGENT_SECRET="test-secret-key"

# Send a heartbeat signal
curl -X POST https://goldclaw-mothership.fly.dev/api/signals \
  -H "Content-Type: application/cloudevents+json" \
  -H "X-Cybernetic-Timestamp: $(date +%s)" \
  -H "X-Cybernetic-Nonce: $(uuidgen)" \
  -H "X-Cybernetic-Signature: $(echo -n "$(date +%s)\n$(uuidgen)\n$(cat heartbeat.json)" | openssl dgst -sha256 -hmac "$AGENT_SECRET" | awk '{print $2}')" \
  -d @- <<EOF
{
  "specversion": "1.0",
  "type": "com.cybernetic.agent.heartbeat",
  "source": "urn:ironclaw:agent:$AGENT_ID",
  "subject": "$AGENT_ID",
  "id": "evt-001",
  "time": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "datacontenttype": "application/json",
  "data": {
    "status": "online",
    "cpu_load": 0.45,
    "memory_mb": 256,
    "disk_gb": 40,
    "current_task": "idle",
    "last_error": null
  }
}
EOF
```

### Test 2: Instruction Creation and Leasing

Create a test instruction in the database (via IEx console):

```bash
flyctl ssh console
iex -S mix

# Create an instruction
alias GoldClaw.Queue.Instruction
Instruction.create("agent-test-001", %{
  "action" => "execute_tool",
  "tool_name" => "echo",
  "tool_args" => %{"message" => "Hello from GoldClaw!"}
})

# Exit IEx
q()
exit
```

### Test 3: Instruction Fetch (Cloud → Edge)

```bash
AGENT_ID="agent-test-001"
AGENT_SECRET="test-secret-key"

# Fetch pending instructions
curl -X GET https://goldclaw-mothership.fly.dev/api/instructions/$AGENT_ID \
  -H "X-Cybernetic-Timestamp: $(date +%s)" \
  -H "X-Cybernetic-Nonce: $(uuidgen)" \
  -H "X-Cybernetic-Signature: $(echo -n "$(date +%s)\n$(uuidgen)" | openssl dgst -sha256 -hmac "$AGENT_SECRET" | awk '{print $2}')"
```

### Test 4: Result Submission (Edge → Cloud)

```bash
AGENT_ID="agent-test-001"
AGENT_SECRET="test-secret-key"

# Submit execution result
curl -X POST https://goldclaw-mothership.fly.dev/api/signals \
  -H "Content-Type: application/cloudevents+json" \
  -H "X-Cybernetic-Timestamp: $(date +%s)" \
  -H "X-Cybernetic-Nonce: $(uuidgen)" \
  -H "X-Cybernetic-Signature: $(echo -n "$(date +%s)\n$(uuidgen)\n$(cat result.json)" | openssl dgst -sha256 -hmac "$AGENT_SECRET" | awk '{print $2}')" \
  -d @- <<EOF
{
  "specversion": "1.0",
  "type": "com.cybernetic.agent.result",
  "source": "urn:ironclaw:agent:$AGENT_ID",
  "subject": "inst-xxxx",
  "id": "res-001",
  "time": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "datacontenttype": "application/json",
  "data": {
    "instruction_id": "inst-xxxx",
    "status": "completed",
    "output": "Hello from GoldClaw!",
    "duration_ms": 42
  }
}
EOF
```

## Verification Checklist

- [ ] Health check returns 200 OK
- [ ] Heartbeat signal accepted (200 OK)
- [ ] Instruction created in database
- [ ] Instruction lease works (atomic update)
- [ ] Result submission completes instruction
- [ ] Shadow agent updates state on heartbeat
- [ ] Goldrush pre-filter dispatches on CPU > 90% or status != "online"
- [ ] HMAC signature verification works
- [ ] Lease reaper expires stuck leases

## Troubleshooting

### Check logs
```bash
flyctl logs
```

### Connect to database
```bash
flyctl postgres connect -a goldclaw-db
```

### Re-run migrations
```bash
flyctl ssh console
mix ecto.reset
```

### View Ecto SQL queries (add to config)
```elixir
config :goldclaw, GoldClaw.Repo,
  log: :debug
```
