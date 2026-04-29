## Agent lifecycle knowledge

You understand how `agent.gen1` entries are configured on the Wippy
keeper platform.

### Visibility — the `class` field

- `class: [public]` makes an agent user-facing — it shows up in the
  `/agents` page and can be opened from the chat surface.
- A child delegate inside a team should NOT have `class: [public]`.
  Only the root agent the user talks to needs it.
- Other class tags act as nav grouping and trait/tool filters
  (`coder`, `orchestrator`, `researcher`, `keeper`, etc.).

### Required fields

- `meta.type: agent.gen1`
- `meta.title` — display name (one or two words, capitalized)
- `meta.comment` — one sentence describing the agent's purpose
- `meta.icon` — `tabler:*` icon
- `prompt` — the system prompt (multiline string or `file://`)
- `model` — class:* alias (smart/coder/fast/nano) or explicit
  `provider:model_id`
- `temperature` — number 0..1
- `max_tokens` — integer (use 16000 for orchestrators, 6000 for
  focused workers, 8000 default)

### Optional but high-leverage fields

- `thinking_effort` — integer 0..100. Non-zero only on reasoning
  models (Claude opus, GPT o-series). Mismatch triggers a runtime
  failure — `analyze` flags this.
- `memory` — array of strings; behavioral overrides that supersede
  the prompt. Best for quick corrections.
- `tools` — array of tool ids or wildcard `namespace:*`. Each id must
  exist as a `meta.type: tool` entry.
- `traits` — array of trait ids. Each must exist as `agent.trait`.
- `delegates` — array of `{name, id, rule, context?}` objects for
  team workflows.

### Model selection

Use `list_models` (or `get_entries kind=registry.entry meta.type=llm.model`)
to see available models. Match capabilities to need:

- Orchestration / planning / design → `class:smart`
- Focused implementation → `class:coder` or `class:fast`
- Cheap tool-calling / classification → `class:nano`

`thinking_effort` only works on models with `extended_thinking` or
`thinking` in their capabilities. `analyze` checks this.

### Memory vs prompt — when to use which

- **Memory**: behavioral correction, scope reminder, edge-case
  guidance. Adds in seconds; reverts cleanly.
- **Prompt**: fundamental responsibility, decision framework, output
  contract. Touch when memories exceed ~20 or the change is
  structural.

### Validation rules

`analyze` reports:
- `model_exists` — model id resolves to an `llm.model` entry
- `supports_thinking` — model declares the capability when
  `thinking_effort > 0`
- `tools_analysis` — direct refs vs wildcards, missing refs, wrong-kind
  refs (e.g. trait id given as a tool)
- `traits_analysis` — valid vs unresolvable trait ids
- `delegates_analysis` — target exists and is `agent.gen1`, no
  duplicate `name` fields, all required fields present
- `is_visible` — has `public` class
- Heuristic recommendations — short prompt, missing title, no
  tools+traits, etc.

Run `analyze` on a staged agent before `push` and resolve every
issue or explicitly accept the recommendations.
