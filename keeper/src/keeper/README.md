# Keeper

Keeper is the Wippy control plane for live registry work, governance, agents,
tasks, MCP access, Hub dependency management, runtime inspection, and component
workflows.

This module ships the compiled Keeper UI as an embedded filesystem and exposes
the APIs needed to operate a Wippy application at runtime. Consumer apps install
`keeper/keeper@0.5.15`; they do not need Keeper frontend source in their own
repository unless they are developing Keeper itself.

## Configuration

Keeper is configured through namespace requirements so applications can bind
their own runtime resources without editing Keeper entries:

- `keeper:api_router` routes Keeper HTTP APIs. Default: `app:api`.
- `keeper:app_db` stores Keeper app-owned data and migrations. Default: `app:db`.
- `keeper:admin_scope` identifies Keeper administrators. Required; bind it to
  the host application's admin security scope.
- `keeper:env_storage` stores Keeper settings and MCP flags. Default: `app.env:store`.
- `keeper:public_gateway` hosts the Keeper MCP HTTP router. Default: `app:gateway`.
- `keeper:mcp_route` controls the MCP client path. Default: `/keeper-mcp/`.
- `keeper:ui_server` serves embedded Keeper UI assets. Default: `app:gateway`.
- `keeper:process_host` runs Keeper-spawned runtime work. Default: `app:processes`.

Keeper imports `wippy/session` as a real module dependency for session and
artifact inspection. If the host app needs non-default session resources,
configure that dependency through standard transitive dependency parameters on
the Keeper install, for example `wippy.session:database_resource`,
`wippy.session:api_router`, `wippy.session:env_storage`, and
`wippy.session:default_host`.

The MCP client URL is the host application's public API base plus
`keeper:mcp_route`. Do not configure clients from Keeper docs against a
hardcoded local port.

### Governance Filesystem Sync

Keeper does not manage any registry namespace by default. This is intentional:
installed modules such as `keeper.*`, `userspace.*`, and `wippy.*` are Hub
dependencies, not source owned by the host application's `src/**` tree.

Dynamic filesystem sync (`sync_from_fs` / `sync_to_fs`) is opt-in. Configure the
comma-separated `GOV_MANAGED_NAMESPACES` environment variable, or update the
same value from Keeper's registry settings, before using FS sync. Typical app
development uses:

```env
GOV_MANAGED_NAMESPACES=app
```

Only include `keeper` when developing Keeper itself from a checkout that
contains Keeper source. Adding a namespace means governance may create, update,
and delete live registry entries in that namespace to match filesystem source.

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

Keeper MCP supports scoped tokens bound to a user identity. The MCP route is
mounted through the host application's configured public gateway and can be
enabled or disabled with Keeper environment settings.
