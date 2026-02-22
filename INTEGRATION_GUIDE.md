# SVE → Automaton Integration Guide

## Overview
This guide covers testing and integrating Automaton skills with the existing SVE infrastructure.

## Prerequisites

1. **Automaton built and configured** ✅
   - `~/.automaton/automaton.json` exists
   - Wallet: `0xD1Fbc3F18255df94DEB98644653583dD4239D2A1` with 18.71 USDC
   - Conway API key: `cnwy_k_K2UgBY5A1I_02dRd-Y8gcss4pk5c5g0j`

2. **SVE ledger accessible** ✅
   - `~/.openclaw/workspace/sve/ledger.sqlite` exists
   - Contains opportunities, leads, experiments tables

3. **SKILL.md files created** ✅
   - Located in `~/.automaton/skills/*/SKILL.md`
   - 4 skills ready: sales_pipeline_sync, sales_followup_send, sales_close_deal, growth_geo_audit, marketing_layers_sync, strategy_hypothesis_generate

## Testing Skills Directly

### Test 1: SVE Ledger Query

Verify SVE ledger has data:

```bash
sqlite3 ~/.openclaw/workspace/sve/ledger.sqlite "
SELECT COUNT(*) as total_opportunities
FROM opportunities
WHERE domain = 'vaos.sh'
"
```

Expected output: `total_opportunities: N` (where N > 0)

### Test 2: Conway Wallet Check

Verify Conway wallet balance:

```bash
npx -y conway-terminal wallet_info
```

Expected output:
```json
{
  "address": "0xD1Fbc3F18255df94DEB98644653583dD4239D2A1",
  "balance": {
    "usdc": 18.71
  },
  "network": "base"
}
```

### Test 3: Domain DNS Check

Verify domain DNS records:

```bash
npx -y conway-terminal domain_dns_list vaos.sh
```

Expected output: Array of DNS records (may be empty if not registered)

### Test 4: Stripe API Check

Verify Stripe secret key is set (for `sales_close_deal`):

```bash
grep STRIPE_SECRET_KEY ~/.openclaw/workspace/sve/config.py
```

Expected: `STRIPE_SECRET_KEY = "sk_test_..."` or similar

## Installing Skills in Automaton

### Method 1: Via Built-in Tool

After starting Automaton, use the `install_skill` tool:

```bash
# Start Automaton
cd ~/.openclaw/workspace/automaton
node dist/index.js --run

# In another terminal, send commands to Automaton
# (This depends on how Automaton exposes its tool interface)
```

### Method 2: Manual Installation

Automaton's skills can also be installed by copying SKILL.md files:

```bash
# Each skill is already in correct format
ls ~/.automaton/skills/

# Skills will be auto-discovered by Automaton
# via loadInstalledTools() in agent/tools.ts
```

### Skill Registration Check

After installation, verify skills are registered:

```bash
sqlite3 ~/.automaton/state.db "
SELECT name, description, enabled, installed_at
FROM skills
WHERE name IN ('sales_pipeline_sync', 'growth_geo_audit', 'marketing_layers_sync')
"
```

## Running Skills via Heartbeat

Automaton's heartbeat daemon runs skills on schedule. Verify configuration:

```bash
cat ~/.automaton/heartbeat.yml
```

Expected content:
```yaml
# Heartbeat Schedule
- name: sales_pipeline_sync
  schedule: "0 */3 * * *"
  description: "Run sales automation (pipeline sync, follow-ups, proposals, contracts)"
- name: growth_geo_audit
  schedule: "0 */6 * * *"
  description: "Run growth operations (geo audit, inject, apply)"
- name: marketing_layers_sync
  schedule: "0 */6 * * *"
  description: "Sync campaigns to Layers API"
- name: strategy_hypothesis_generate
  schedule: "0 */12 * * *"
  description: "Run strategy operations (repo analysis, experiments, decisions)"
```

## Verification Checklist

### Phase 3.1: Skill Execution Tests

- [ ] `sales_pipeline_sync` fetches opportunities from SVE ledger
- [ ] `sales_pipeline_sync` dispatches to webhook rails
- [ ] `sales_followup_send` sends follow-ups with idempotency
- [ ] `sales_close_deal` checks Stripe sessions correctly
- [ ] `growth_geo_audit` queries Conway wallet balance
- [ ] `growth_geo_audit` checks domain availability
- [ ] `marketing_layers_sync` connects to Layers API
- [ ] `strategy_hypothesis_generate` analyzes pipeline status

### Phase 3.2: Integration Tests

- [ ] Webhook dispatch succeeds to `sales_crm_webhook_url`
- [ ] Stripe session checking works (test with live session)
- [ ] Conway terminal commands execute without errors
- [ ] Idempotency keys prevent duplicate dispatches
- [ ] Artifact files are written to `~/.openclaw/workspace/sve/artifacts/`

### Phase 3.3: Automaton Integration

- [ ] Skills appear in Automaton's `list_skills` tool output
- [ ] Heartbeat daemon executes skills on schedule
- [ ] Skill execution logs appear in `turns` table
- [ ] Tool call results appear in `tool_calls` table
- [ ] Errors are logged and retried appropriately

## Debugging

### Check Automaton Logs

```bash
# View recent turns (agent reasoning)
sqlite3 ~/.automaton/state.db "
SELECT timestamp, state, thinking
FROM turns
ORDER BY timestamp DESC
LIMIT 10
"

# View tool call results
sqlite3 ~/.automaton/state.db "
SELECT turn_id, name, result, error
FROM tool_calls
ORDER BY created_at DESC
LIMIT 20
"
```

### Check Skill Artifacts

```bash
# View sales pipeline sync artifacts
ls -la ~/.openclaw/workspace/sve/artifacts/sales/

# View growth audit artifacts
ls -la ~/.openclaw/workspace/sve/artifacts/growth/

# View webhook stubs
ls -la ~/.openclaw/workspace/sve/webhook_stubs/
```

### Verify Webhook Dispatch

Check SVE's outbox for dispatch records:

```bash
sqlite3 ~/.openclaw/workspace/sve/ledger.sqlite "
SELECT id, intent, idempotency_scope, idempotency_key, created_ts
FROM outbox_events
WHERE intent IN ('sales.pipeline_sync', 'sales.followup_send')
ORDER BY created_ts DESC
LIMIT 10
"
```

## Next Steps After Testing

1. **If skills execute successfully**: Proceed to Phase 4 - parallel testing with SVE
2. **If skills fail to execute**: Debug errors in Automaton's `tool_calls` table
3. **If webhook dispatch fails**: Verify SVE webhook URLs and API keys in config
4. **If Stripe integration fails**: Verify `STRIPE_SECRET_KEY` environment variable

## Rollback Plan

If Automaton skills don't work as expected:

1. **Keep SVE running**: It continues to operate independently
2. **Archive Automaton logs**: Save `.automaton/state.db` for debugging
3. **Fallback to SVE**: Continue using SVE heartbeat/tick services
4. **Fix integration issues**: Update SKILL.md files and retry

## Contact & Support

- Automaton docs: `~/.openclaw/workspace/automaton/docs/`
- SVE source: `~/.openclaw/workspace/sve/`
- Issue tracking: Update `STATUS.md` with findings
