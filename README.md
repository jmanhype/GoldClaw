# GoldClaw

Jido-IronClaw Hybrid Orchestrator — A Cybernetic Control Loop for Edge-Cloud Agentic Computing.

## Overview

GoldClaw establishes a bidirectional control loop between edge devices and a central orchestrator using CloudEvents over HTTP. The architecture is designed for:

- **Interoperability** — CloudEvents 1.0 wire format
- **Idempotency** — Instruction leasing and deduplication
- **Resilience** — Goldrush pre-filtering prevents noisy storms

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Edge Node (IronClaw)                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐ │
│  │ IronClaw     │  │ Routines     │  │ WASM Sandbox         │ │
│  │ Runtime      │──│ Engine       │──│ (Secure Execution)   │ │
│  └──────────────┘  └──────────────┘  └──────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ CloudEvents 1.0
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│               The Mothership (Jido/Elixir)                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐ │
│  │ Phoenix      │→ │ Goldrush     │→ │ Fleet Dispatcher     │ │
│  │ Gateway      │  │ Pre-Filter   │  │ (Shadow Registry)     │ │
│  └──────────────┘  └──────────────┘  └──────────────────────┘ │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐                            │
│  │ Instruction  │  │ Shadow Agents│                            │
│  │ Queue        │  │ (Jido 2.0)   │                            │
│  └──────────────┘  └──────────────┘                            │
└─────────────────────────────────────────────────────────────────┘
```

## Components

### Edge (IronClaw)
- **Runtime**: Rust/WASM-based local-first agent
- **Heartbeat**: Periodic `agent.heartbeat` signals to Mothership
- **Poller**: Pulls and executes `agent.instruction` commands
- **Result**: Returns `agent.result` on completion

### Cloud (Jido/Elixir)
- **Gateway**: Phoenix endpoint with specversion normalization (1.0 ↔ 1.0.2)
- **Pre-Filter**: Goldrush-powered event filtering (dispatches only on significant events)
- **Dispatcher**: Fleet-wide signal routing to Shadow agents
- **Queue**: Instruction leasing and management

## Protocol (AMCP)

### agent.heartbeat (Edge → Cloud)
```json
{
  "specversion": "1.0",
  "type": "com.cybernetic.agent.heartbeat",
  "source": "urn:ironclaw:agent:uuid-1234-5678",
  "subject": "uuid-1234-5678",
  "id": "evt-001-transmission-id",
  "time": "2026-02-21T12:00:00Z",
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
```

### agent.instruction (Cloud → Edge)
```json
{
  "specversion": "1.0",
  "type": "com.cybernetic.agent.instruction",
  "source": "urn:jido:mothership",
  "subject": "inst-555",
  "id": "delivery-777",
  "time": "2026-02-21T12:01:00Z",
  "datacontenttype": "application/json",
  "data": {
    "instruction_id": "inst-555",
    "lease_expires_at": "2026-02-21T12:02:00Z",
    "priority": "high",
    "action": "execute_tool",
    "tool_name": "git_clone",
    "tool_args": {
      "repo": "https://github.com/example/repo",
      "dest": "./workspace/repo"
    }
  }
}
```

### agent.result (Edge → Cloud)
```json
{
  "specversion": "1.0",
  "type": "com.cybernetic.agent.result",
  "source": "urn:ironclaw:agent:uuid-1234-5678",
  "subject": "inst-555",
  "id": "res-001",
  "time": "2026-02-21T12:01:05Z",
  "datacontenttype": "application/json",
  "data": {
    "instruction_id": "inst-555",
    "status": "completed",
    "output": "Cloning into './workspace/repo'...",
    "duration_ms": 4500
  }
}
```

## Security

- **HMAC Signing**: `X-Cybernetic-Signature = HMAC-SHA256(AGENT_SECRET, Timestamp + "\n" + Nonce + "\n" + Body)`
- **TLS 1.3**: Strict HTTPS for all transport
- **WASM Sandboxing**: Filesystem/network access restricted to `/workspace/` and allowlisted domains
- **TUF**: Over-the-air updates follow The Update Framework

## Deployment

- **Mothership**: `fly launch` (Elixir/Phoenix)
- **Edge**: `ironclaw onboard` (Rust/WASM)

## License

MIT License — See [LICENSE](LICENSE) for details.

## Status

Version: 3.2 (Final Hardening)
