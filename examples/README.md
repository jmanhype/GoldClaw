# GoldClaw Examples

This folder contains example configurations and usage patterns for GoldClaw V3.2.

## Edge Agent Configuration Examples

### Heartbeat Example
File: `jido_uplink.json`

Demonstrates:
- Cron trigger with jitter for preventing thundering herds
- HMAC signature calculation
- CloudEvents 1.0 heartbeat payload

### Instruction Poller Example
File: `instruction_poller.json`

Demonstrates:
- Polling for pending instructions
- Conditional tool execution (only runs if status = 200)
- HMAC-signed result submission

## Environment Setup

Create a `.env` file based on the example:

```bash
# Mothership URL (update with your deployed Mothership URL)
MOTHERSHIP_URL=https://goldclaw-mothership.fly.dev

# Agent Credentials
AGENT_ID=your-agent-uuid-here
AGENT_SECRET=your-secure-hmac-secret-here
```

## Quick Start

1. Copy example JSON files to your IronClaw agent's config directory
2. Set up environment variables
3. Start your IronClaw agent
4. The agent will begin sending heartbeats and polling for instructions

## Testing Instructions

Send a test heartbeat:

```bash
curl -X POST https://your-mothership-url/api/signals \\
  -H "Content-Type: application/json" \\
  -d '{
    "specversion": "1.0",
    "type": "com.cybernetic.agent.heartbeat",
    "source": "urn:ironclaw:agent:your-agent-id",
    "subject": "your-agent-id",
    "id": "evt-001",
    "time": "2026-02-21T12:00:00Z",
    "data": {
      "status": "online",
      "cpu_load": 0.45,
      "memory_mb": 512,
      "disk_gb": 80
    }
  }'
```

Create a test instruction (via database insert):

```sql
INSERT INTO instructions (id, instruction_id, agent_id, status, payload, created_at, updated_at)
VALUES (
  gen_random_uuid(),
  'test-instruction-001',
  'your-agent-id',
  'pending',
  '{"action": "echo", "message": "Hello GoldClaw!"}',
  NOW(),
  NOW()
);
```

Then fetch and execute instruction:

```bash
curl -X GET https://your-mothership-url/api/instructions/your-agent-id
```

For more information on AMCP protocol and system architecture, see the main project README.
