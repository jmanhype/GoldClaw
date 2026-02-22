# SVE → Automaton Migration Summary

## Progress Overview

### Phase 1: Automaton Setup ✅ COMPLETE

**Configuration:**
- Wallet: `0xD1Fbc3F18255df94DEB98644653583dD4239D2A1`
- Balance: 18.71 USDC
- Network: Base (eip155:8453)
- State: sleeping (ready to run)
- Model: gpt-5.2
- Version: 0.1.0

**Components Configured:**
- Genesis prompt with SVE operations
- Heartbeat schedule (6 tasks)
- Treasury policy (budget limits)
- Model strategy (tier-based fallback)

### Phase 2: Skills Development ✅ COMPLETE (10/17)

**Skills Built:**
- Sales: 6/6 ✅
- Growth: 3/3 ✅
- Marketing: 1/1 ✅
- Strategy: 1/5 (20%)

### Phase 3: Skills Integration 🔄 IN PROGRESS

**Converted to SKILL.md Format (4 critical skills):**
1. ✅ `sales_pipeline_sync` - Pipeline sync with webhook dispatch
2. ✅ `sales_followup_send` - Follow-up messaging with idempotency
3. ✅ `sales_close_deal` - Stripe session checking & deal closing
4. ✅ `growth_geo_audit` - Conway wallet, domain, DNS audits
5. ✅ `marketing_layers_sync` - Layers API campaign sync
6. ✅ `strategy_hypothesis_generate` - Growth hypothesis generation

**Integration Points Completed:**
- ✅ State DB: Skills query SVE SQLite ledger
- ✅ Conway Client: Skills use `npx conway-terminal`
- ✅ Stripe Integration: Checkout session checking
- ✅ Webhook Dispatch: Idempotent dispatch with fallback
- ✅ Idempotency: Hour/day-based deduplication

**Remaining Work:**
- ⏳ Test skill execution locally
- ⏳ Install skills in Automaton
- ⏳ Verify outputs match SVE behavior

### Phase 4-5: Testing & Decommission ⏳ NOT STARTED

## Architecture Comparison

### SVE (Python)
- Custom heartbeat/tick services
- SQLite ledger with action_requests, opportunities, leads tables
- Conway client via adapter pattern
- Rigid command schema (e.g., `/mandate <intent>`)

### Automaton (TypeScript + SKILL.md)
- ReAct loop (Think → Act → Observe)
- SQLite state DB with turns, tool_calls, skills tables
- Conway SDK integration
- Flexible skills (markdown-based, easily extensible)
- Self-modification capabilities

## Key Advantages of Automaton

1. **Flexibility:** Add skills without editing code
2. **Self-modification:** Can optimize itself over time
3. **Survival pressure:** Must create value or die
4. **Official support:** Actively maintained by Conway
5. **Replication:** Can spawn child agents
6. **Extensibility:** Skill system for new capabilities

## Migration Timeline

| Phase | Status | Effort |
|--------|--------|---------|
| Phase 1: Setup | ✅ Complete | 1-2 hours |
| Phase 2: Skills Development | ✅ Complete | 1-2 days |
| Phase 3: Integration | 🔄 In Progress | 1-2 hours |
| Phase 4: Decommission | ⏳ Not Started | 30 minutes |
| Phase 5: Testing | ⏳ Not Started | 1-2 days |

**Total Estimated:** 3-5 days

## File Locations

### SVE (existing)
- Code: `~/.openclaw/workspace/sve/`
- Ledger: `~/.openclaw/workspace/sve/ledger.sqlite`
- Config: `~/.openclaw/workspace/sve/config.py`
- Artifacts: `~/.openclaw/workspace/sve/artifacts/`

### Automaton (new)
- Code: `~/.openclaw/workspace/automaton/`
- State DB: `~/.automaton/state.db`
- Config: `~/.automaton/automaton.json`
- Skills: `~/.automaton/skills/*/SKILL.md`
- Heartbeat: `~/.automaton/heartbeat.yml`

## Risk Mitigation

### Low Risk
- Both systems can run in parallel
- SVE continues to operate independently
- No data migration required (skills read SVE ledger)

### Medium Risk
- Skills need testing before production
- Webhook dispatch errors may occur
- Stripe integration needs verification

### Rollback Plan
If Automaton doesn't work:
1. Keep SVE running
2. Archive Automaton logs
3. Debug integration issues
4. Fix and retry

## Next Actions

1. **Test skills locally** - Run manual execution tests
2. **Start Automaton** - Begin agent loop
3. **Monitor execution** - Check logs for errors
4. **Parallel testing** - Run both systems for 24-48 hours
5. **Decommission SVE** - Stop services if Automaton succeeds

## Documentation

- **Migration Plan:** `MIGRATION_PLAN.md`
- **Status Tracking:** `STATUS.md`
- **Integration Guide:** `INTEGRATION_GUIDE.md`
- **Skills README:** `~/.automaton/skills/README.md`

## Contact & Support

- Automaton Repository: https://github.com/Conway-Research/automaton
- Conway Docs: https://docs.conway.tech
- Discord: https://discord.gg/clawd
