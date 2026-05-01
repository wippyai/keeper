# Release Notes

## keeper/keeper 0.5.6

`keeper/keeper@0.5.6` republishes the Keeper 0.5.5 package using the fixed Wippy
resource packer/reader from runtime PR #259, so embedded UI assets can be
extracted by the corrected install path.

### Verification

- Reproduced the old extractor failure on `keeper/keeper@0.5.5`:
  `extract embedded resource keeper.components:ui_static_fs: read resource file assets/tsMode-BI5rsYdF.js: wapp: decompress: unexpected EOF`.
- Verified the fixed runtime binary can unpack `keeper/keeper@0.5.5` and read
  the embedded `ui_static_fs` assets.
- Wippy runtime PR #259 clean worktree:
  `make test`, `./tests/app/test.sh`, and `make lint` pass.

## keeper/keeper 0.5.5

`keeper/keeper@0.5.5` hardens runtime Hub installs, dependency state sync, MCP
tooling, and the registry-backed requirement UI.

### Highlights

- Dependency directive create/update/delete now triggers full state
  reconciliation, so generated module entries cannot remain stale after install
  or uninstall.
- Hub uninstall preserves `ns.dependency` kind in delete changesets and blocks
  unsafe uninstall when migrations are still applied unless the user chooses a
  migration policy.
- Install planning exposes transitive requirements with expected kinds and live
  registry suggestions while still allowing explicit typed ids.
- MCP root/admin token endpoints were removed in favor of scoped actor-bound
  token creation through the public Keeper route.
- Agent delegation, knowledge tools, and inspect/component traits are organized
  under the Keeper tool surface for remote development.
- Keeper UI source rebuild controls are hidden for installed modules; embedded
  static assets remain the served package surface.

### Verification

- `keeper.state.service:test`, `keeper.state.tools:test`, and `keeper.hub:test`
  pass 193/193 in a live app.
- Live Hub smoke installed `wippy/embeddings@0.3.13` with transitive
  requirements, ran its migration up, rejected unsafe uninstall, then
  uninstalled with `migration_policy=down` and verified cleanup.
- Focused Keeper lint for state and Hub namespaces reports no issues.
- `keeper/usage` lint reports no issues.
- Frontend tests pass 48/48.
- `make publish-dry-run` packed both modules successfully before publish.

## keeper/usage 0.1.1

`keeper/usage@0.1.1` updates the usage API tests and package metadata for the
Keeper 0.5.5 release.

## keeper/keeper 0.5.4

`keeper/keeper@0.5.4` makes Hub requirement selection fully user-bound and
registry-aware for apps with arbitrary namespaces.

### Highlights

- Install plans now expose the expected value kind for requirements, for example
  `http.router` for endpoint router bindings.
- The Hub install UI always lets the user type an exact registry id or contract
  value; package defaults are shown as metadata, not pre-filled guesses.
- Registry suggestions are live entries only. They are selectable, but never
  required to use `app:*` names.
- Manually typed resource values are validated against the expected registry
  kind before install. Invalid values stay visible in the dialog with a clear
  reason and are not sent as install parameters.

### Verification

- `keeper.hub:test` passes 49/49 in the running app.
- `wippy lint --ns keeper.hub,keeper.hub.*` reports no issues.
- Frontend Hub API tests pass.
- Frontend type-check and production build pass.
- Live plan smoke: `tenant.web:missing` is rejected as an invalid `http.router`.
- Live plan smoke: `keeper.mcp:router` is accepted as a valid non-`app:*`
  router requirement value.
- UI smoke: the install dialog shows live router suggestions, a manual
  `Enter http.router id or contract value` input, and disables install for an
  invalid typed router id.

## keeper/keeper 0.5.3

`keeper/keeper@0.5.3` hardens Hub dependency install planning and the
configuration dialog.

### Highlights

- Hub install plans no longer auto-apply package defaults that do not resolve to
  the expected registry kind.
- Router requirements now surface actual `http.router` entries as selectable
  values, keeping the user in the loop for app-specific routing choices.
- The Hub install dialog uses a real select for registry-backed suggestions and
  keeps a custom override input for explicit values.
- Hub uninstall now exposes the migration policy clearly and sends
  `migration_policy=down` when the user chooses rollback.

### Verification

- `keeper.hub:test` passes 47/47.
- `wippy lint --ns 'keeper.hub,keeper.hub.*'` reports no issues.
- Frontend Hub API tests pass.
- Frontend type-check and production build pass.
- Real app smoke: installed `wippy/dummy` through the requirement select with
  `app:api`, verified `GET /api/v1/dummy/ping`, then uninstalled cleanly.
- Real app smoke: installed `userspace/scheduler@0.4.9`, ran migrations up,
  verified the schedules endpoint, then uninstalled with migrations down.

## keeper/keeper 0.5.0

`keeper/keeper@0.5.0` is the v5 packaging release. It prepares Keeper to be
installed as a proper Wippy module instead of being copied into every app.

### Highlights

- Keeper is now organized as a module monorepo with `keeper/keeper` and
  `keeper/usage`.
- The core Keeper UI is shipped as an embedded static filesystem.
- Consumer apps no longer need to rebuild Keeper from app-local frontend source.
- Component discovery skips module-owned Keeper source when `keeper/keeper` is
  installed as a dependency.
- Component discovery rejects invalid static bundle directory names, including
  whitespace-suffixed artifact directories.
- The Components page no longer exposes the old fake UI edit-session controls.
- Hub APIs cover browse, version lookup, README lookup, install planning,
  dependency install/uninstall, migration listing, and migration execution.
- MCP configuration is represented through Keeper settings and scoped token APIs.

### Requirements

The module keeps runtime integration explicit through namespace requirements:

- `keeper:api_router`
- `keeper:app_db`
- `keeper:admin_scope`
- `keeper:env_storage`
- `keeper:public_gateway`
- `keeper:ui_server`
- `keeper:process_host`

Install planning should surface any missing requirement values before applying a
Hub install. Requirement values must come from user/admin input or registry-backed
selection, not from heuristics.

### Verification

- Published and installed `keeper/keeper@0.4.4` as an intermediate validation
  release for the embedded UI/component scanner fixes.
- Verified the installed app serves Keeper assets, including the previously
  failing dynamic chunk `utils-CSjTgnrH.js`.
- Verified the app component catalog no longer exposes `@wippy/app-keeper` as a
  local rebuildable component when Keeper is module-installed.
- Verified direct lookup of `@wippy/app-keeper` returns `component not found` in
  the consuming app.
- Verified scanner lint for `keeper.components.build`.
- Verified Keeper frontend build during publish.

### Notes

The 0.5.0 branch is intentionally larger than the 0.4.x line because it carries
the module extraction layout. The 0.4.4 release exists as a narrow published
checkpoint for the UI bundle and component scanner fixes.
