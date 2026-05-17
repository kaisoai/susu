# susu — Design

The verified task marketplace where context corrections trade hands.

## One sentence

Requesters post tasks, experts refine them, executors do the work, and the scorer is the payment gate.

## How it works

```
┌─────────────────────────────────────────────────────────────┐
│                         susu                                 │
│                                                              │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐               │
│  │Requester │    │  Expert  │    │ Executor │               │
│  │          │    │          │    │          │               │
│  │ Posts    │    │ Refines  │    │ Does the │               │
│  │ task     │    │ task     │    │ work     │               │
│  └────┬─────┘    └────┬─────┘    └────┬─────┘               │
│       │               │               │                     │
│       ▼               ▼               ▼                     │
│  ┌─────────────────────────────────────────┐                │
│  │           Task (accumulated context)     │                │
│  │                                          │                │
│  │  context/        rubric.toml             │                │
│  │  ├─ spec.md      [rubric]                │                │
│  │  ├─ issue.md     name = "..."            │                │
│  │  ├─ expert/      [[criteria]]            │                │
│  │  │  └─ notes.md  name = "auth"           │                │
│  │  └─ github/      weight = 1.0            │                │
│  │     └─ thread.md added_by = "expert:dan" │                │
│  └──────────────────────┬──────────────────┘                │
│                          │                                   │
│                          ▼                                   │
│  ┌──────────────────────────────────────────┐               │
│  │              irie check                   │               │
│  │                                           │               │
│  │  Staged eval:                             │               │
│  │  1. Opus understands (context + rubric)   │               │
│  │  2. Panel scores (haiku + sonnet)         │               │
│  │  3. Opus decides                          │               │
│  │                                           │               │
│  │  Or tournament:                           │               │
│  │  irie compare proposal_a proposal_b ...   │               │
│  └──────────────────────┬──────────────────┘                │
│                          │                                   │
│                          ▼                                   │
│                    ┌───────────┐                             │
│                    │  Score    │                             │
│                    │  passes? │                             │
│                    └─────┬─────┘                             │
│                     yes/ \no                                 │
│                     /     \                                  │
│              ┌─────▼┐   ┌─▼──────┐                          │
│              │ PAY  │   │ NO PAY │                          │
│              └──────┘   └────────┘                          │
└─────────────────────────────────────────────────────────────┘
```

## The task lifecycle

```
Phase 1: POST
  Requester creates task
  → description, specs, budget, deadline
  → initial context/ directory
  → anansi auto-gathers related context (GitHub, docs, etc.)

Phase 2: REFINE
  Expert refines the task (the highest-leverage phase)
  → adds constraints, gotchas, domain knowledge
  → anansi interviews the expert, translates to:
     - rubric.toml criteria (persists across task type)
     - context files (one-time, this task)
  → expert never sees TOML — they "refine the task"
  → prevents wrong-path execution before it starts

Phase 3: EXECUTE
  Executor (human or AI agent) does the work
  → sees enriched context: spec + auto-gathered + expert refinements
  → can request clarification (triggers more expert context)
  → produces output artifact

Phase 4: VERIFY
  irie scores the output
  → staged eval against accumulated context + rubric
  → score determines payment
  → expert can provide additional context during verification
     ("the test is wrong not the code" → rubric adjustment)

Phase 5: SETTLE
  Score passes threshold → executor gets paid
  Expert gets paid for refinement + any rubric contributions
  Rubric criteria with provenance → royalties on future use
```

## What gets paid

### Requester pays
- Task bounty (to executor on pass)
- Verification fee (to irie infrastructure)
- Expert refinement fee (to expert)

### Executor earns
- Task bounty (on verification pass)
- Reputation (Bradley-Terry, per task type)

### Expert earns
Two streams:

**Per-task refinement** — paid for each task they refine. Direct context that helps this specific task. Flat fee or hourly.

**Rubric royalties** — paid every time a criterion they contributed is used in future evaluations. The expert who adds "check for rate limiting in v3 API calls" to the api-migration rubric earns a fraction every time that criterion is evaluated. This compounds.

```
Expert contribution         Payment model        Compounds?
─────────────────          ──────────────        ──────────
"Use OAuth2 not API keys"  Per-task fee          No
  → added to context/

"Check for rate limiting"  Royalty per use        Yes
  → added to rubric.toml
  → used in 500 future evals
```

## Reputation: Bradley-Terry

Same methodology as LM Arena ($1.7B). Pairwise comparison resists gaming better than star ratings.

- Each verified task completion is a "battle"
- Executors and experts accumulate Elo-like ratings
- Ratings are **per task type**, not aggregate (a great frontend dev might be mediocre at infra)
- Statistical confidence intervals — new participants have wide intervals that narrow with history
- Transparent and auditable — all evaluations use irie, all results are reproducible

## Intermediate representation

Users see "tasks." Under the hood:

```
task-12345/
├── context/                    ← accumulated context
│   ├── spec.md                 ← requester provided
│   ├── github/                 ← anansi gathered
│   │   ├── issue.md
│   │   └── comments.md
│   └── expert/                 ← expert refinements
│       └── refinement-001.md
├── rubric.toml                 ← what "done" means
│   ├── criteria with provenance
│   └── versioned, auditable
├── submissions/                ← executor outputs
│   ├── agent-output-001/
│   └── agent-output-002/
└── results/                    ← irie evaluation logs
    └── (Inspect AI native format)
```

Context is tagged by source (automated/expert/requester). irie weights by source trust. The rubric tracks who added each criterion and when.

## The tools

```
anansi                    irie                      susu
─────────                 ────                      ────
Gathers context           Generates rubrics         Prices the exchange
  - crawls GitHub         Runs staged eval          Manages task lifecycle
  - interviews experts    Pairwise tournament       Tracks reputation
  - auto-discovers docs   Produces Inspect logs     Handles payment
                                                    Routes expert attention

Format interfaces only — no code imports between tools
  context/ (markdown)  →  rubric.toml  →  Inspect logs (JSON)
```

## What exists vs what's needed

| Component | Status |
|---|---|
| anansi GitHub gathering | Working (221 lines) |
| anansi expert interviews | Not built |
| irie check (staged eval) | Working (980 lines) |
| irie compare (tournament) | Working |
| susu task posting | Not built |
| susu payment integration | Not built |
| susu reputation system | Not built |
| susu expert matching | Not built |
| Rubric provenance tracking | Designed, not built |
| Rubric royalty system | Designed, not built |

## Key design decisions

**Task refinement is the user abstraction.** Nobody interacts with TOML or context directories. Experts "refine tasks." The system translates.

**Context before execution is highest leverage.** Expert refinement in Phase 2 prevents wrong-path work entirely. Expert review in Phase 4 explains failures. Both are valuable; Phase 2 is more valuable.

**Rubric contributions compound.** Direct corrections fix one task. Rubric criteria fix a category. Price accordingly — royalties, not flat fees.

**All evaluation is reproducible.** Every irie evaluation produces an Inspect AI log. Any party can re-run `inspect eval task.py` to verify the score. Trust = transparency.

**Loose coupling.** anansi, irie, and susu are separate repos with format-level interfaces. Any tool can be swapped. Any verifier can replace irie. Any context gatherer can replace anansi.
