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

## Bootstrap Strategy

Sequential. One bet at a time. Team of 2, one part-time.

### Phase 0: Dogfood (now)

Dennis posts real work from Upbound. Marcelle is the expert. Agents execute. irie scores. Two-person marketplace running on real tasks through the actual tools. Proves the lifecycle before opening to anyone.

**Goal:** 10 real tasks scored end-to-end. Identify every friction point.

### Phase 1: Two parallel motions (month 1-3)

**Self-service (bottom-up):** Ship irie as a pip-installable tool. Developer runs `irie check` on their code, gets a score + explanation. Free, open source, no account needed. Adoption metric: installs + GitHub stars. This builds the user base that feeds everything downstream.

**Expert engagements (top-down):** Sell context correction to companies using AI agents. "We interview your domain experts via anansi, improve your evaluation context, and show you the accuracy difference." $500-$2K per engagement. No marketplace UX needed — just anansi + irie + an expert + an invoice.

The two motions feed each other: self-service users discover they need expert context (their scores are low). Expert engagement customers discover their teams want the self-service tool.

**Self-service discovery for agents:** We want agent builders and developers to discover irie organically — like Moltbook for agent verification. Developer has an agent that produces output, runs `irie check`, gets a score and a rubric they didn't have to write. The friction should be near-zero: pip install, set API key, one command. The discovery loop is: agent produces work → developer isn't sure if it's good → irie check → structured score with explanation → developer trusts (or doesn't) the agent.

**Experts are us initially:** Dennis and Marcelle are the first experts. We offer free refinements — N free anansi interviews / context corrections for early users. Not because it's a business model. Because we need to learn: what questions do experts actually ask? What context actually moves the needle? What does the expert UX feel like? Every free session teaches us something about the product. We can't design expert tools without being experts first.

**Expand the expert network slowly:** Start with our highly technical friends — people we trust, who have deep domain expertise, who will give honest feedback on the tools and the experience. Not a public marketplace. A curated group of 10-20 experts we know personally. This is how the best marketplaces start: handpicked supply, quality over quantity, learn what works before opening the floodgates.

**Goal:** 200+ irie installs. 20+ free expert sessions (us). 5 friends onboarded as experts. Enough data to know what expert tools need to look like before building marketplace UX.

### Phase 2: Free irie check with expert upsell (month 3-6)

Open `irie check` as a free tool. Anyone can verify agent output. The score shows where the output is weak. The upsell: "Want an expert to improve your context and re-score? $X."

```
Free: irie check solution.py "fix the bug" → 2.8/5.0
Paid: expert adds context via anansi interview → re-check → 4.2/5.0
      "Here's what the expert caught that your agent missed."
```

The free check is lead gen. The expert session is revenue. The delta between scores is the sales pitch.

**Goal:** 100 free checks/month. 10% conversion to expert sessions.

### Phase 3: Marketplace (month 6+)

Only after Phase 1 and 2 prove demand. Requesters post tasks, experts bid to refine them, agents execute, irie scores, payment flows. Bradley-Terry reputation from Phase 1-2 history seeds the marketplace with credible expert profiles.

Build marketplace UX only after you have:
- Experts with track records (from Phase 1)
- Requesters who've paid for context correction (from Phase 1-2)
- A conversion funnel that works (from Phase 2)

### What we're NOT doing (yet)

- **Competitions/bounties.** Cash furnace without VC money. Defer.
- **Government partnerships.** 6-12 month relationship cycle. Year 2.
- **Public leaderboards.** Marketing, not revenue. Do it when customers care.
- **Community-contributed tasks.** Nobody contributes to tools with zero users. Users first.
