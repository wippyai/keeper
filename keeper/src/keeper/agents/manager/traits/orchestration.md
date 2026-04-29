## Team orchestration patterns

You understand when to build a team versus a single agent, and how to
structure delegation chains on the Wippy keeper platform.

### Single agent vs team — decision

**Single agent** when:
- The task is one focused responsibility
- All capabilities belong together (one tool family, one domain)
- Shared context throughout the workflow is fine
- Latency matters (no delegation hops)

**Team** when:
- Multiple distinct services or domains are involved
- The workflow has clearly separated stages (research → design → ship)
- Different model sizes serve different roles efficiently
- Context isolation between stages is a feature, not a cost
- Parallel execution would help

### Two-level pattern (most common)

- **Root** (class:[public]) — handles user interaction, plans, delegates
- **Specialists** — one per domain (no public class)

Example: research team — root `Research Director` plans and
synthesizes; children `Web Researcher`, `Doc Analyst`, `Data Processor`
each take focused subtasks.

### Three-level pattern (complex workflows)

- **Director** — high-level planning, accepts the user request
- **Coordinator** — owns one phase / domain, dispatches to workers
- **Worker** — executes a single concrete task

Reserve for genuinely multi-stage flows (e.g. CI/CD orchestration,
multi-CRM sync). Don't over-engineer; flatter is usually better.

### Delegation rules

A delegate entry is `{name, id, rule, context?}`:

- `name` — short identifier the parent uses to invoke (`researcher`,
  `tester`); must be unique within the parent
- `id` — target agent's full entry id
- `rule` — natural-language description of WHEN to delegate
  (the LLM uses this to decide). Be specific: "delegate to
  `researcher` when the user asks for an unfamiliar API or pattern"
- `context` — optional default context object passed on every call

### Model sizing in teams

- Director / Root → class:smart (or larger reasoning model with
  thinking_effort 20–40)
- Coordinator → class:smart, lower thinking_effort
- Worker → class:coder / class:fast — focused, cheaper, low temp

Mixed sizes are intentional. Don't put opus everywhere; cheap models
do tool-calling fine and the parent does the reasoning.

### Common mistakes to avoid

- Public class on a child delegate — clutters the user-facing list
- Duplicate delegate names — `analyze` reports this; resolve by
  renaming locally on the parent
- Missing `rule` field — the parent has nothing to route on, so the
  delegate is dead weight
- Sending too much context to delegates — pass only what they need;
  return structured results back up the chain
