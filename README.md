# Keeper

This repository packages Keeper as a Wippy module monorepo.

- `keeper/` publishes `keeper/keeper`, the core Wippy control plane.
- `usage/` publishes `keeper/usage`, the optional usage analytics module.

Each child directory is an independent Wippy module with its own `wippy.yaml`,
`wippy.lock`, source tree, tests, and optional frontend bundle.

## Modules

### `keeper/keeper@0.5.3`

Keeper provides the operator surface for a Wippy app:

- registry and namespace governance
- task orchestration and agent workflows
- MCP token management and MCP transport
- Hub dependency install/uninstall planning
- frontend component discovery, builds, screenshots, and UI automation tools
- logs, process/system inspection, tests, knowledge, changesets, and state graph APIs

The compiled Keeper UI is embedded in the module as `keeper.components:ui_static_fs`.
Consumer apps should install the module and serve the embedded UI; they should not
rebuild Keeper from stale app-local source unless they are actively developing this
repository.

### `keeper/usage`

Keeper Usage adds analytics pages and APIs on top of `wippy/usage`. It is separate
so deployments can install or remove usage analytics independently.

## Requirements

`keeper/keeper` is configured through namespace requirements, so app projects can
bind Keeper to their own runtime resources without editing Keeper entries:

- `keeper:api_router` defaults to `app:api` and is applied to Keeper HTTP APIs.
- `keeper:app_db` defaults to `app:db` and is used for Keeper app-owned tables.
- `keeper:admin_scope` defaults to `app.security:admin`.
- `keeper:env_storage` defaults to `app.env:store` and stores Keeper settings and MCP flags.
- `keeper:public_gateway` defaults to `app:gateway` and is used for the optional public MCP mount.
- `keeper:ui_server` defaults to `app:gateway` and serves embedded Keeper UI assets.
- `keeper:process_host` defaults to `app:processes` for Keeper-spawned runtime work.

The module also declares dependency requirements for Wippy runtime modules such as
`wippy/agent`, `wippy/dataflow`, `wippy/llm`, `wippy/migration`, `wippy/security`,
`wippy/session`, `wippy/test`, and `wippy/views`.

See [RELEASES.md](RELEASES.md) for release notes.

## Hub Flow

The Keeper Hub APIs are designed for runtime dependency management:

- browse modules and versions
- read module README content
- inspect installed dependencies
- plan installs, including transitive requirements and required parameters
- install or uninstall dependencies
- list and run migrations when the installed module provides them

Install planning should be used before install so the UI can show the complete
requirement list and keep the user in the loop. Do not guess requirement values.

## Verify

```sh
make lint
make publish-dry-run
```

## Publish

```sh
make publish-keeper
make publish-usage
```

## License

Keeper modules are distributed under the Business Source License 1.1. See
[LICENSE](LICENSE). The module metadata in `keeper/wippy.yaml` and
`usage/wippy.yaml` uses the same `BSL-1.1` identifier.
