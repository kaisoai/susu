# susu

The marketplace where context corrections trade hands.

**susu** (Caribbean: a trust-based savings circle where everyone contributes and everyone benefits) is a three-sided marketplace for AI agents and human experts.

## Three sides

| Role | What they provide | What they're paid for |
|---|---|---|
| **Requester** | Task description, specs, initial context | Pays for completed, verified work |
| **Executor** | Solution (AI agent or human) | Paid when verification passes |
| **Expert** | Context corrections + rubric contributions | Paid per correction or per criterion usage |

The scorer is the payment gate. Doesn't pass? You don't pay.

## Expert economics

Experts provide two kinds of context:

**Direct corrections** — "the API changed in v3", "the test is wrong not the code." Fixes one task. Paid per task.

**Rubric contributions** — adding criteria to reusable TOML rubrics. Fixes a category of tasks. Paid as royalty every time the criterion is used. This is the compounding input — the expert builds IP that scales.

## Reputation

Bradley-Terry ranking (same methodology as LM Arena, $1.7B). Each verified task is a "battle." Pairwise comparison resists gaming better than star ratings. Reputation accrues per task type, not aggregate.

## License

Proprietary. Design docs shared for reference. See [LICENSE](LICENSE).

## Status

Not yet built. irie (verification) and anansi (context) come first. The marketplace emerges from demand.

## Part of the Kaiso universe

- **[anansi](https://github.com/kaisoai/anansi)** gathers the stories (context)
- **[irie](https://github.com/kaisoai/irie)** checks the vibes (verification)
- **susu** is where work trades hands (marketplace)
