# susu — Security & Access Control

## The Problem

In susu, multiple parties interact with the same task context:
- **Requester** posts sensitive specs (business logic, internal APIs, credentials)
- **Expert** needs enough context to refine the task, but not everything
- **Executor** (often an AI agent) needs enough to do the work
- **anansi** crawls sources and interviews humans — what can it access?
- **irie** evaluates output — what context does it see?

Not everyone should see everything. An expert refining "fix the auth bug" doesn't need to see the actual API keys. An AI executor shouldn't see salary data in a Jira ticket that's contextually relevant.

## Architecture: RBAC at the Manifest Level

The manifest already tracks provenance (source type, source ID). Access control is a layer ON TOP of the manifest — each entry gets visibility scopes.

```json
{
  "file": "api_keys.md",
  "source": {"type": "requester", "id": "acme-corp"},
  "visibility": ["requester", "executor"],
  "redacted_for": ["expert", "interviewer"],
  "summary_only_for": ["expert"]
}
```

### Visibility scopes

```
requester   — can see everything they posted
executor    — sees task spec + relevant context, NOT billing/internal docs
expert      — sees enough to refine, NOT PII/secrets/internal data
interviewer — anansi's interview agent, MOST restricted
irie        — sees everything needed to score, NOT secrets
public      — visible to anyone (task description, rubric)
```

### How it works

```
anansi gather github:org/repo#123 -o context/
  → gathers issue + comments + PRs
  → manifest entries default to visibility: ["all"]

requester refines:
  "mark api_keys.md as requester+executor only"
  → manifest entry updated: visibility: ["requester", "executor"]

anansi interview -o context/
  → interview agent reads manifest
  → only sees entries where "interviewer" is in visibility
  → OR sees redacted summaries for restricted entries
  → asks questions based on what it CAN see

irie check submission.py context/
  → reads manifest
  → filters context by irie's visibility scope
  → scores against visible context only
```

### Redaction vs exclusion

Two modes for restricted content:

**Excluded:** Entry completely invisible. Interview agent doesn't know it exists.

**Summary-only:** Entry replaced with its `summary` field. Interview agent knows "there's an API configuration doc" but doesn't see the actual keys. This lets it ask the expert about API requirements without accessing secrets.

```json
{
  "file": "internal_api_config.md",
  "source": {"type": "requester"},
  "visibility": ["requester", "executor"],
  "summary_only_for": ["expert", "interviewer", "irie"],
  "summary": "Internal API configuration — OAuth2 endpoints, rate limits, auth requirements"
}
```

The expert sees the summary and might say "make sure they use the v3 OAuth2 flow" — providing the context correction without ever seeing the actual config.

## MCP Server Permissions

When anansi uses MCP servers to gather context, each server connection has a scope:

```
anansi gather github:org/repo#123 --scope expert
  → only fetches public issue data, comments
  → does NOT fetch: org-private repos, internal wikis, member emails

anansi gather slack:C049HHMV9SM --scope executor  
  → fetches channel messages relevant to the task
  → does NOT fetch: DMs, private channels, user profiles with PII
```

The `--scope` flag tells anansi what role it's gathering for. MCP servers respect the scope by filtering their responses. This is enforced at the MCP server level, not by anansi — anansi just passes the scope through.

## Token/Credential Isolation

```
┌─────────────────────────────────────────┐
│ susu task boundary                       │
│                                          │
│  requester's MCP tokens → full access    │
│  expert's MCP tokens → read-only, scoped │
│  executor's sandbox → network-isolated   │
│  irie's eval → no external network       │
│                                          │
│  No party sees another party's tokens.   │
│  susu holds tokens, delegates scoped     │
│  access per operation.                   │
└─────────────────────────────────────────┘
```

susu acts as the credential broker. When anansi needs to crawl a requester's private repo for context, susu provides a scoped token with read-only access to the specific repo, not the requester's full GitHub token.

## What Needs Building

| Component | Status |
|---|---|
| Manifest visibility fields | Design (this doc) |
| Manifest filtering by scope | Not built |
| anansi scope-aware gathering | Not built |
| anansi redacted summaries | Not built |
| MCP scope passthrough | Not built (depends on MCP server support) |
| susu credential broker | Not built |
| Executor sandbox isolation | Handled by Inspect AI (Docker sandbox) |

## Principles

- **Least privilege.** Each role sees the minimum context needed for their job.
- **Redact, don't exclude when possible.** Summaries preserve intent without exposing secrets.
- **Enforce at the source.** MCP servers filter, not anansi. anansi just passes scopes.
- **Audit trail.** The manifest records who saw what. Every access is logged.
- **Requester controls visibility.** The requester decides what each role can see. Defaults are restrictive — opt-in to share, not opt-out to restrict.
