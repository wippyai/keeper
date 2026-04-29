# Release Notes

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
