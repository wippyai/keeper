# Release Notes

## keeper/keeper 0.5.18

`keeper/keeper@0.5.18` preserves legacy Jet view support while keeping Keeper's
modern frontend build pipeline focused on compiled component pages.

### Highlights

- Generic state editing can create `template.set` and `template.jet` entries for
  legacy `view.page` plugins.
- Governance filesystem sync now has regression coverage for materializing
  `template.jet` pages as `.jet` source files without inventing source files for
  `template.set` entries.
- Integrate build handling skips `template.jet` file sources because they are
  rendered by `wippy/views`, not by Keeper's Vue/Vite component builder.

### Verification

- `wippy lint --ns keeper.state,keeper.gov,keeper.develop.integrate.handlers,keeper.changeset.service --limit 200 --no-color`
- `wippy run test -- keeper.state.persist:materialize_test keeper.gov.service:sync_test keeper.develop.integrate.handlers:build_handler_test keeper.develop.integrate.handlers:view_handler_test keeper.changeset.service:diff_render_test keeper.state.tools:test`
- `wippy run test` in `framework/src/views/test`

## keeper/keeper 0.5.16

`keeper/keeper@0.5.16` temporarily bundles the Keeper Git review workflow into
the main Keeper module until it is split back into a standalone module.

### Highlights

- `keeper.git.*` registry entries are now shipped with `keeper/keeper`.
- The compiled Git UI is embedded as `keeper.components:git_static_fs` and
  served at `/app/keeper-git` through the app-provided UI server requirement.
- Git API endpoints are included in the `keeper:api_router` requirement so apps
  with non-default API routers can install Keeper without hardcoded `app:api`.
- Git scan tests now pass explicit managed namespace config, preserving the
  safe governance default of managing no namespaces unless configured.

### Verification

- `wippy lint --ns 'keeper,keeper.*' --summary --limit 200 --no-color` checked
  460 entries with no issues.
- `wippy run test keeper.git.service:async_task_test keeper.git.service:snapshot_test keeper.git.detectors:detectors_test keeper.git.flows:cluster_factory_test keeper.git.flows:clusterer_test keeper.git.flows:clusterer_parallel_test keeper.git.flows:file_diff_test keeper.git.flows:git_scan_test keeper.git.flows:llm_groups_test keeper.git.flows:push_test keeper.git.flows:rebuild_test keeper.git.flows:split_test keeper.git.flows:suggest_split_test`
  passed 128/128.
- `make publish-keeper-dry-run` passed and packed the bundled module.

## keeper/keeper 0.5.15

`keeper/keeper@0.5.15` improves governance filesystem sync feedback and one-shot
namespace sync for agents and remote MCP operators.

### Highlights

- `sync_from_fs` and `sync_to_fs` now accept an optional `managed_namespaces`
  argument for one-shot app syncs without mutating stored governance config.
- Sync responses now report unmanaged namespace skips in `stats` and
  `details.skipped_unmanaged`, so "no changes needed" cannot hide source files
  that were ignored by the namespace allow-list.
- Governance prompts now tell agents to pass the app namespace explicitly when
  `GOV_MANAGED_NAMESPACES` is unset, and to avoid adding `keeper` unless the
  checkout actually contains Keeper source.
- Download/upload paths share the same namespace filter semantics, including
  child namespace matching and sibling rejection.

### Verification

- `wippy run test keeper.gov.service:upload_test keeper.gov.service:download_test keeper.gov.tools:test keeper.gov.service:test`
  passed 74/74.
- `wippy run test keeper.gov.service:test keeper.gov.service:changeset_test keeper.mcp:test keeper.mcp.surface:surface_test keeper.gov.service:upload_test keeper.gov.service:download_test keeper.gov.tools:test`
  passed 243/243.
- `wippy lint --cache-reset --ns keeper --ns 'keeper.*'` checked 403 entries
  with no issues.

## keeper/keeper 0.5.10

`keeper/keeper@0.5.10` corrects the MCP configuration documentation.

### Highlights

- README requirement docs now include `keeper:mcp_route`.
- MCP docs describe the app-gateway route as the client URL surface instead of
  implying a separate optional/public endpoint.
- User-facing docs no longer point operators toward a hardcoded local MCP port.

### Verification

- `make lint WIPPY=/tmp/wippy-packcheck`

## keeper/keeper 0.5.9

`keeper/keeper@0.5.9` tightens the task-agent boundary after the KB curator split.

### Highlights

- Design phase prompts now route missing registry / KB / docs facts through the
  `research` delegate instead of advertising direct lookup tools the design
  agent does not own.
- Research phase remains the explicit read-capable context capture phase:
  `search_knowledge`, registry exploration, docs lookup, and task-local
  `save_context` are allowed; durable KB writes remain curator-only.
- The repository `make lint` target now checks the full `keeper,keeper.*`
  namespace instead of a partial subset, so task/agent/develop regressions are
  covered by the default lint gate.

### Verification

- `make lint WIPPY=/tmp/wippy-packcheck`
- `wippy lint --ns 'keeper,keeper.*' --summary --limit 200 --no-color`

## keeper/keeper 0.5.8

`keeper/keeper@0.5.8` republishes the Keeper 0.5.7 source using the released
`github.com/wippyai/wapp v0.1.1` resource reader/writer and the restored Wippy
pack integrity gate.

### Verification

- Wippy runtime PR #261 switches from the `wapp` pseudo-version to
  `github.com/wippyai/wapp v0.1.1`.
- `wapp` PR #1 is merged to `main`, tagged `v0.1.1`, and released on GitHub.
- Focused runtime package tests passed:
  `go test ./cmd/wippy/cmd ./cmd/internal/entries ./boot/build/stages ./boot/deps/hub`.
- Keeper publish dry-run passed with the fixed runtime binary:
  `make publish-keeper-dry-run WIPPY=/tmp/wippy-packcheck`.
- Local unpack smoke passed by packing Keeper UI, installing the pack from a temp
  lock with `options.unpack_modules: true`, and verifying
  `ui_static_fs/assets/tsMode-BI5rsYdF.js` extracted at 22062 bytes.

## keeper/keeper 0.5.7

`keeper/keeper@0.5.7` separates task-time context research from durable
knowledge curation.

### Highlights

- `/knowledge/research` and `/knowledge/learn` now spawn
  `keeper.agents:kb_curator`, the write-capable KB agent, instead of the
  read-only task researcher.
- Context-chain gatherers no longer carry KB or documentation tools. They gather
  live registry/filesystem precedents only; KB/docs gaps are delegated to
  `keeper.agents:researcher`.
- Agent prompts now describe the handoff explicitly: task researcher returns
  lookup findings in output, phase agents decide what to persist with
  `save_context`, and durable KB writes belong to the curator.

### Verification

- Focused lint for touched Keeper namespaces passed:
  `wippy lint --ns 'keeper.agents,keeper.develop,keeper.develop.*,keeper.knowledge.service' --summary --limit 200 --no-color`.
- Monorepo lint passed: `make lint`.
- Publish packaging dry-run passed: `make publish-keeper-dry-run`.
- Added regressions for context gatherer tool boundaries, read-only task
  researcher capabilities, and KB service curator dispatch.

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
- `keeper:mcp_route`
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
