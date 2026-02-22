# CLAUDE-SPR.md — Claude Agent Operating System

**Purpose:** Formal specification for Claude agents working on YAWL v6.0.0 codebase
**Status:** LIVE (February 22, 2026)

---

## Header

**YAWL v6.0.0 | A := μ(O) | ∂drift(A)/∂t → 0 | Σ = {Java25, Maven, JUnit, XML/XSD} | O ⊨ PetriNet+BPM**

---

## Π (Priority Lattice — Resolve Conflicts by Argmax Over Ordered Set)

```
⊤ := H ≻ Q ≻ Ψ ≻ Λ ≻ Ω
∀conflict(x,y): resolve := argmax_{i∈⊤}(⊤[i] ∋ {x,y})
```

**Circuit:** Ψ ∘ Λ ∘ H ∘ Q ∘ Ω | □(¬skip(gate_i)) ∀i | hook ≡ autopilot ∈ {PreToolUse, PostToolUse}
**Uncertainty → stop ∧ re-read(⊤) | ¬proceed without gate resolution**

---

## Ψ := Observatory(O) | Fact-Based Knowledge System

```
I(Ψ)/I(grep) = 100
token_cost(facts) ≪ token_cost(search)
```

```
∀f ∈ facts/*.json: cost(f) ≈ 50T | cost(grep_equiv) ≈ 5000T
∴ ∀query: use(f) ∧ ¬grep
```

### Fact Files

**F := {modules.json, gates.json, reactor.json, shared-src.json, tests.json, dual-family.json, deps-conflicts.json, maven-hazards.json}

### Staleness Detection

```
∀f ∈ F: stale(f) → exec(scripts/observatory/observatory.sh)
integrity: SHA256(f) ≡ receipts/observatory.json
|files_explored| > 3 for single answer → STOP ∧ run(observatory.sh)
facts ≺ exploration
```

---

## Λ := Build System | Partial Order Compilation

```
partial_order: compile ≺ test ≺ validate ≺ deploy
∀pre-commit: □(β(*) = GREEN)
```

### Build Gates

```
β₀ := dx.sh compile
β(m) := dx.sh -pl m
β(*) := dx.sh all
β ∈ {β₀, β(m), β(*)}
```

### Validation

```
¬∃commit: β(*) ≠ GREEN
web(CLAUDE_CODE_REMOTE=true) → proxy(127.0.0.1:3128) auto-active
static_analysis: mvn clean verify -P analysis
∀module m: β(m) ≺ β(*) in DX loop
```

---

## H := Guards | Prohibited Pattern Enforcement

```
enforcer: hyper-validate.sh
exit_code(H_violation) = 2
H ∩ emit = ∅
```

### Prohibited Patterns

```
H_set := {TODO, FIXME, XXX, HACK, LATER, mock, stub, fake, empty_return, silent_fallback, lie, placeholder}

∀c ∈ emit: H_set ∩ c = ∅ ∨ c ≡ throw(UnsupportedOperationException)
¬∃ middle ground
```

### Hook

```
hook: Write|Edit → scan(H_set)
blocked → fix_real(c) ∧ ¬workaround
14-point detection regex
```

---

## Q := Invariants | Real Implementation or Throw

```
∀m ∈ methods: (real_impl(m) ∨ throws(UOE,m)) ∧ ¬mock(m) ∧ ¬silent_catch(m)
```

### Code-Documentation-Test Alignment

```
∀m: code(m) ≡ docs(m) ≡ signature(m)
```

### Deferred Work

```
deferred_work(m) → UOE(m)
¬∃"for now" ∈ codebase
```

### No Silent Failures

```
¬silent_fallback: catch(e){return fake} → prohibited
¬lie: contract(m) ≡ impl(m) | real ∨ throw
```

---

## κ (Quantum Singularity) | Single-Axis Commits

```
∀commit: |{axis(commit)}| = 1
drift(A) ∝ |axes(commit)| − 1
```

### Commit Axes

```
κ ∈ {Toolchain, Dependency, Schema, Engine_semantic, MCP_A2A, Resourcing}
|κ_per_commit| = 1
```

### Multi-Axis Handling

```
|axes| ≥ 2 → split_scope ∨ spawn(τ)
¬proceed with multi-axis in single session/commit
```

### Quantum Singularity Workflow

```
pick(κ) → read(Ψ.facts/modules.json) → read(R[κ]) → DX_loop → Ω
```

---

## Ω := Git Workflow | Branch & Commit Policy

```
P(force_push) = 0
P(amend_pushed_commit) = 0
∀stage: git_add(files) ≠ git_add(.)
```

### Branch Naming

```
branch_pattern := "claude/" ++ desc ++ "-" ++ sessionId
push: git push -u origin branch
```

### Atomic Commits

```
∀commit: |logical_changes| = 1
∀f ∈ emit: modify_freely
∀f ∈ ⊗: confirm(user) ∧ ¬assume
```

### Session URLs

```
session_url ∈ commit_msg
∀push_fail(network): retry(n) with backoff(2ⁿs), n ∈ {1,2,3,4}
```

---

## C (Channels) | Free-Modify vs User-Confirmation

```
emit := {src/, test/, schema/, .claude/}
⊗ := {root/, docs/, *.md}
```

### Channel Rules

```
emit ∩ ⊗ = ∅
f ∈ emit → free
f ∈ ⊗ → ask_user
f ∉ emit ∪ ⊗ → ask_user
```

### Post-Action Hooks

```
PostWrite/Edit: hook_green → commit
hook_blocked → fix_real → NEW_commit (¬amend)
```

---

## τ ⊕ μ ⊕ ∅ (Agent Scaling — Choose Exactly One)

### τ (Tau) — Team-Based Collaboration

```
τ(N): N ∈ [2,5]∩ℤ, ∀i≠j: orthogonal(κᵢ,κⱼ), messaging+iteration, cost ≈ [3C,5C]
DEFAULT iff N≥2
```

#### Team Validation

```
validate(τ): team-recommendation.sh "task"
∀tm: shared-src.json → file_conflicts(tmᵢ ∩ tmⱼ) = ∅
```

#### Team Circuit

```
τ_circuit(tmᵢ): Ψ(claim_task) ∘ β(mᵢ) ∘ H(hook) ∘ Q(real_impl) ∘ msg(teammates) ∘ Ω(mark_done)
```

#### Team Error Handling

```
τ_error: idle(30min) → msg(tm)
crash(5min) → checkpoint ∧ reassign
DX_fail → fix ∧ retry
```

#### Team Consolidation

```
τ_consolidation: β(*) ∧ H_clear → git_add(∪ᵢfiles(tmᵢ)) → atomic_commit → push
```

### μ (Mu) — Independent Agents

```
μ(N): ∀tasks: independent ∧ report_only ∧ ¬messaging, within-session, cost ≈ C + Σᵢsummary(i)
```

### ∅ (Empty) — Solo Work

```
∅: |κ|=1, cost ≈ C, fastest
use iff ¬∃collaboration_benefit ∧ ¬∃parallel_value
```

---

## Γ := Architecture | 6 Domains, 89 Packages

```
domains(O) = {engine, elements, stateless, integration, schema, test}
```

### Entry Points

**Stateful:**
- YEngine
- YNetRunner
- YWorkItem
- YSpecification

```
→ entry_points(E_stateful)
```

**Stateless:**
- YStatelessEngine
- YCaseMonitor
- YCaseImporter
- YCaseExporter

```
→ entry_points(E_stateless)
```

**Integration:**
- YawlMcpServer(MCP)
- YawlA2AServer(A2A)

```
→ entry_points(E_integration)
```

### Package Structure

```
∀p ∈ packages: |p| = 89 ∧ package-info.java(p) ≠ ∅
read(package-info) ≺ read(any_source)
```

### Interfaces

```
Interfaces: A(design) | B(client) | E(events) | X(extended)
each enforces contract(Ω)
```

---

## R := Rules | 17 Domain-Specific Rules

```
|R| = 17
path_match(f, Rᵢ) → auto_activate(Rᵢ)
¬duplicate_in(CLAUDE.md)
```

### Rule Domains

```
R_domains = {
  teams/, build/, schema/, engine/,
  integration/, java25/, elements/, testing/,
  security/, observability/, scripts/,
  docker/, config/, resourcing/
}
```

### Domain Rule Mapping (κ → Rᵢ)

**Toolchain** → build/dx-workflow.md
**Dependency** → config/static-analysis.md
**Schema** → schema/xsd-validation.md
**Engine** → engine/workflow-patterns.md
**MCP_A2A** → integration/mcp-a2a-conventions.md
**Resourcing** → resourcing/resource-allocation.md
**Security** → security/crypto-and-tls.md
**Testing** → testing/chicago-tdd.md
**Java25** → java25/modern-java.md

---

## μ(O) := Subagents | Agent Roles

```
.claude/agents/
Task(a₁,...,aₙ) ∈ single_msg
∀n: n ≤ 5
```

### Generic Subagents

```
μ_generic := {engineer, reviewer, validator}
```

### YAWL-Specific Subagents

```
μ_yawl := {
  yawl-architect,
  yawl-engineer,
  yawl-integrator,
  yawl-reviewer,
  yawl-tester,
  yawl-validator,
  yawl-production-validator,
  yawl-performance-benchmarker
}
```

### All Subagents

```
μ_all := μ_generic ∪ μ_yawl
∀aᵢ ∈ μ_all: isolated_context ∧ summary(result) → lead
```

---

## ℂ (PreToolUse Checklist) | Gates Before Tools

```
□(checklist) before ∀tool_call ∈ {Bash, Task, Read, Glob, Grep, Write, Edit}
```

### Gate Checks

**Ψ_gate:**
```
stale(facts)? → observatory.sh
N≥2κ? → team-recommendation.sh → τ ∨ μ ∨ ∅
```

**H_gate:**
```
H_set ∩ content ≠ ∅? → fix_real
```

**Q_gate:**
```
real_impl(m) ∨ throws(UOE,m)?
```

**Ω_gate:**
```
f ∈ emit? → free
f ∈ ⊗? → confirm(user)
sessionId set? → branch_pattern valid?
```

### Post-ToolUse Hooks

```
PostToolUse: hook=green → proceed
hook=blocked → fix_real → NEW_commit (¬amend ¬workaround)
```

---

## Σ (STOP Conditions) | Halt Triggers

```
∀s ∈ Σ: triggered(s) → halt ∧ re-anchor
¬violation ⇒ drift(A) ↑
```

### Stop Conditions

1. **No module code:**
```
∄module(code) → read(Ψ.facts/modules.json)
```

2. **Excessive file search:**
```
|files_searched| > 3 → observatory.sh
```

3. **Multi-axis ambiguity:**
```
N≥2κ ∧ ambiguous → team-recommendation.sh
```

4. **Excessive teammates:**
```
|τ_teammates| > 5 → split_into_sequential_phases
```

5. **Hook blocked on Write/Edit:**
```
hook_blocked(Write|Edit) → fix_real_violation ∧ ¬workaround
```

6. **Context overflow:**
```
ctx_usage > 70% → checkpoint ∧ batch
```

7. **Uncertain modification:**
```
f ∈ ⊗ ∧ uncertain → ask(user) ∧ ¬assume
```

8. **Deferred work:**
```
deferred_work → throw(UnsupportedOperationException)
```

### Team-Specific STOP Conditions

**τ (Team mode):**
```
idle_tm > 30min → msg ∧ await(5min)
task > 2hr → msg_status
msg_timeout > 15min → URGENT
```

---

## Summary

**Formal Operating System for Claude Agents**

| Component | Symbol | Purpose |
|-----------|--------|---------|
| **Priority Lattice** | Π | Conflict resolution order |
| **Observatory** | Ψ | Fact-based knowledge (50T vs 5000T) |
| **Build System** | Λ | Partial order compilation |
| **Guards** | H | Prohibited pattern enforcement |
| **Invariants** | Q | Real implementation or throw |
| **Quantum Singularity** | κ | Single-axis commits |
| **Git Workflow** | Ω | Branch & commit policy |
| **Channels** | C | Free-modify vs user-confirm |
| **Agent Scaling** | τ ⊕ μ ⊕ ∅ | Collaboration modes |
| **Architecture** | Γ | 6 domains, 89 packages |
| **Rules** | R | 17 domain-specific rules |
| **Subagents** | μ | Agent roles |
| **PreToolUse** | ℂ | Gates before tools |
| **STOP Conditions** | Σ | Halt triggers |

**Guarantee:** ∂drift(A)/∂t → 0

**Status:** LIVE — Enforced on all agent work.

---

*Formal specification. Not a style guide. Mathematical guarantees.*
