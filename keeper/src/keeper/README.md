# Keeper

Keeper is the Wippy control plane for live registry work, governance, agents,
tasks, MCP access, Hub dependency management, runtime inspection, and component
workflows.

This module ships the compiled Keeper UI as an embedded filesystem and exposes
the APIs needed to operate a Wippy application at runtime. Consumer apps install
`keeper/keeper@0.5.2`; they do not need Keeper frontend source in their own
repository unless they are developing Keeper itself.

## Configuration

Keeper is configured through namespace requirements so applications can bind
their own runtime resources without editing Keeper entries:

- `keeper:api_router` routes Keeper HTTP APIs. Default: `app:api`.
- `keeper:app_db` stores Keeper app-owned data and migrations. Default: `app:db`.
- `keeper:admin_scope` identifies Keeper administrators. Default: `app.security:admin`.
- `keeper:env_storage` stores Keeper settings and MCP flags. Default: `app.env:store`.
- `keeper:public_gateway` hosts the optional public MCP mount. Default: `app:gateway`.
- `keeper:ui_server` serves embedded Keeper UI assets. Default: `app:gateway`.
- `keeper:process_host` runs Keeper-spawned runtime work. Default: `app:processes`.

## Hub

Keeper Hub can browse modules, read module documentation, plan dependency
installs, show transitive requirements, install/uninstall modules, and run
module migrations when requested. Install plans are the canonical place to ask
the user for missing requirement values; Keeper should not guess them.

Hub dependency install and uninstall publish exact dependency registry changes
through governance, then update `wippy.lock`. They do not use development
workspace branch diffs, so source branches cannot accidentally broaden a module
install into unrelated Keeper or application changes.

## MCP

Keeper MCP supports scoped tokens bound to a user identity. Local internal MCP
can be exposed separately from the optional public MCP route, and public MCP is
gated by Keeper environment settings.
