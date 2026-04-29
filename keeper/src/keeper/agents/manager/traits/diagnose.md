## Agent diagnosis from sessions

You diagnose misbehaving agents by reading their recent sessions, not
by guessing from the prompt.

### Workflow

1. **Find the sessions** — use `keeper.agents.tools:sessions`
   (`action: list`) filtered by `agent_id`. Pick the most recent 3–5
   that show the reported issue.
2. **Read transcripts** — `action: get` on each session_id; look at
   the user message, the agent's tool calls, and its final reply.
3. **Identify the trigger** — what specific input made the agent go
   off-track? Was it ambiguous phrasing, a missing tool result, an
   invalid argument shape?
4. **Pick the smallest fix** that prevents recurrence. Apply,
   re-validate via `analyze`, push.

### Common failure modes and fixes

**Agent misunderstands intent**
→ Memory: "When the user asks X, do Y, not Z"
   (one short, declarative sentence).

**Agent over-complicates simple requests**
→ Memory: "Prefer the smallest sufficient change. Don't refactor
   adjacent code unless the user asked."

**Agent exceeds scope / does work outside its role**
→ Memory + prompt review. If the role boundary is in the prompt and
   the agent ignores it, the prompt may be too long — extract the
   boundary into memory where it gets higher attention.

**Tool failures**
→ Run `analyze` first. The fix is usually one of:
   - Tool entry doesn't exist → wrong id; correct it
   - Wrong arg shape → check the tool's `input_schema`
   - Tool itself is broken → redirect to `keeper.agents:engineer`

**Context loss across delegation**
→ The parent isn't passing required context. Update the delegate's
   `context` default or change the parent's prompt to include the
   handoff data explicitly.

**Model limits hit**
→ Either the prompt is too long (extract to traits) or the task is
   too big for the model class (upgrade or split via team).

### Fix strategies, in priority order

1. **Memory addition** — fastest, cheapest, easiest to revert.
2. **Tool / trait swap** — when the capability mismatch is structural.
3. **Prompt edit** — when the responsibility itself needs to change.
4. **Team restructure** — when the agent is doing two jobs that
   should be different agents.
5. **Engineer redirect** — when the issue is platform-level
   (missing tool, missing model capability).

### When NOT to diagnose

If the user explicitly asks for a feature change ("add the ability
to X") rather than reporting broken behavior, that's not a diagnosis
job — that's a normal enhancement. Skip the session-reading step
and go to the lifecycle workflow.
