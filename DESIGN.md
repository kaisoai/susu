# susu — Design

The marketplace where context corrections trade hands.

## Architecture

```
                              kaiso.ai
                    ┌──────────────────────────┐
                    │          susu             │
                    │   task lifecycle engine   │
                    │                          │
                    │  ┌────────────────────┐  │
                    │  │  credential broker │  │
                    │  │  (scoped tokens)   │  │
                    │  └────────┬───────────┘  │
                    │           │               │
                    └───────────┼───────────────┘
                                │
              ┌─────────────────┼──────────────────┐
              │                 │                   │
   ┌──────────▼───────┐ ┌──────▼──────┐  ┌────────▼────────┐
   │    requester      │ │   expert    │  │    executor     │
   │                   │ │             │  │                 │
   │ posts task +      │ │ refines via │  │ does the work   │
   │ initial context   │ │ interview   │  │ (human or AI)   │
   └──────────┬────────┘ └──────┬──────┘  └────────┬────────┘
              │                 │                   │
              ▼                 ▼                   ▼
   ┌──────────────────────────────────────────────────────┐
   │              task (filesystem)                         │
   │                                                       │
   │  context/                     rubric.toml             │
   │  ├─ manifest.json             (generated or expert)   │
   │  │  (provenance + RBAC)                               │
   │  ├─ issue.md (automated)      submissions/            │
   │  ├─ comments.md (automated)   └─ output.py            │
   │  ├─ interview_001.md (expert)                         │
   │  └─ spec.md (requester)       results/                │
   │                               └─ (Inspect AI logs)    │
   └───────────────────────┬──────────────────────────────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
      ┌───────▼──┐  ┌─────▼─────┐  ┌──▼─────────┐
      │  anansi  │  │   irie    │  │  Inspect AI │
      │          │  │           │  │             │
      │ gather   │  │ rubric    │  │ eval        │
      │ interview│  │ gen +     │  │ execution   │
      │          │  │ staged    │  │ engine      │
      │ context  │  │ eval      │  │             │
      │ files +  │  │           │  │ reproducible│
      │ manifest │  │ scorer    │  │ logs        │
      └──────────┘  │ design    │  └─────────────┘
                    └───────────┘
```

## Task Lifecycle

```
PHASE 1: POST
  requester creates task → description, specs, budget
  anansi gather → automated context from GitHub, Slack, docs (via MCP)
  manifest.json tracks provenance + visibility scopes

PHASE 2: REFINE  (highest leverage — prevents wrong-path execution)
  anansi interview → agent reads existing context, asks expert targeted questions
  expert talks naturally → anansi structures into context files + rubric input
  RBAC: interviewer sees scoped context (summaries for sensitive entries)

PHASE 3: EXECUTE
  executor (human or AI agent) sees enriched context
  produces output artifact in submissions/

PHASE 4: VERIFY
  irie staged eval:
    opus understands problem (all visible context + rubric)
    panel scores (haiku + sonnet parallel)
    opus decides
  or irie compare (pairwise tournament if multiple submissions)
  results stored as Inspect AI logs (reproducible)

PHASE 5: SETTLE
  score passes threshold → executor paid
  expert paid for refinement
  reputation updated (Bradley-Terry, per task type)
```

## What Gets Paid

| Role | What they provide | Payment |
|---|---|---|
| Requester | Task + initial context + budget | Pays bounty + fees |
| Expert | Context corrections via interview | Per-task refinement fee |
| Executor | Solution artifact | Bounty on verification pass |

## Reputation: Bradley-Terry

Same methodology as LM Arena ($1.7B valuation). Each verified task is a "battle." Pairwise results accumulate into Elo-like ratings per task type. Transparent, auditable, resists gaming better than star ratings.

## Security

RBAC at the manifest level. Each context entry has visibility scopes. MCP servers enforce scopes at the source. susu acts as credential broker — no party sees another party's tokens. See [SECURITY.md](SECURITY.md).

```
visibility: ["requester", "executor"]     → expert can't see
summary_only_for: ["expert", "irie"]      → sees summary, not content
```

## The Tools

```
anansi                    irie                    susu
──────                    ────                    ────
gather <uri>              check <artifact>        task lifecycle
interview                 compare <artifacts>     credential broker
                                                  reputation (B-T)
                                                  payment/settlement
manifest.json ──────────→ rubric.toml ──────────→ Inspect logs
(provenance + RBAC)       (what to check)         (reproducible results)
```

No code imports between tools. Format-level interfaces only.

## What We Own vs OSS

| Component | Own | OSS |
|---|---|---|
| Crawling intelligence (what to fetch) | ✓ | |
| Expert interview agent | ✓ | |
| Manifest + provenance format | ✓ | |
| Rubric generation intelligence | ✓ | |
| Scorer design (0-5 per criterion) | ✓ | |
| Bradley-Terry reputation | ✓ | |
| Task lifecycle engine | ✓ | |
| Source connectors | | MCP servers |
| Scoring execution | | Inspect AI |
| LLM API | | Anthropic SDK |
| Payment rails | | Stripe / MPP |

Own the intelligence. Use OSS for infrastructure.

## What Exists

| Component | Status |
|---|---|
| anansi gather (GitHub issues, repos) | Working (592 lines) |
| anansi interview (expert Q&A agent) | Working |
| irie check (staged eval) | Working (980 lines) |
| irie compare (pairwise tournament) | Working |
| Manifest provenance | Working |
| RBAC visibility fields | Designed |
| susu task lifecycle | Designed |
| susu credential broker | Designed |
| Bradley-Terry reputation | Designed |
| Payment integration | Not designed |
| MCP server integration | Architecture ready |
