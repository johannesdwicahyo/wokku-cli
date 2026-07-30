# Changelog

## 0.6.0 — 2026-07-30

### Removed

- Removed `do`, `buildpacks`, `storage`, and log-drain commands — the underlying wokku-cloud endpoints were retired when the platform moved off Dokku (Track B). `wokku logs` is unchanged.

## 0.5.3 — 2026-06-26

### Fixed

- `databases:create` and `addons:shared:enable` no longer report success optimistically. The CLI used to print "Created"/"Enabled" on any 2xx — including a `202 Accepted` ("queued") — so a database or shared engine that was still provisioning, or that failed afterward, looked done. Both commands now poll until the resource is actually `running` (then "Created"/"ready"), `error` (a clear failure + nonzero exit), or a timeout ("still provisioning — check `wokku addons APP` / `databases:info`"). Poll cadence is tunable via `WOKKU_POLL_ATTEMPTS`/`WOKKU_POLL_INTERVAL`.

## 0.5.2 — 2026-06-06

### Changed

- API endpoint is now hard-locked to `https://wokku.cloud/api/v1`. Wokku is a managed-cloud product, so the endpoint is no longer configurable: removed the `WOKKU_API_URL` env override, the `auth:login --url` flag, and persisting `api_url` to `~/.wokku/config`. `mcp:install`/`mcp:switch` now pass only the token to the plugin (the MCP plugin's endpoint is fixed too, v1.2.0). Eliminates the class of bug where a stale/wrong API URL silently pointed the CLI at a dead host.

## 0.5.1 — 2026-06-04

### Fixed

- `wokku tunnel` — generated `frpc.toml` now writes the session token to a top-level `[metadatas]` block (in addition to `[proxies.metadatas]`). Without the top-level block frpc sent no token on the Login op, so the gateway rejected the connection before any proxy was set up. Adds `loginFailExit = true` so frpc bails immediately on auth failure instead of retrying forever.

## 0.5.0 — 2026-06-04

`wokku tunnel` — share a local port at `https://<sub>.wokku.dev` in one command. Pairs with wokku-cloud canonical backlog 3.4.

### Added

- `wokku tunnel PORT [--subdomain S] [--app A]` — provisions a tunnel session via `POST /api/v1/tunnels`, downloads `frpc` v0.62.1 to `~/.wokku/bin/` on first run (~10 MB, one time), writes a per-process `frpc.toml`, execs frpc against the wokku-tunnel gateway, and closes the session on Ctrl-C.

Plan-tiered: Free gets 1 tunnel with a random subdomain and 2h timeout (watermarked); Solo+ unlocks custom subdomains and 3+ concurrent tunnels with no timeout. Server-side enforcement — the CLI just surfaces whichever the API returned.

## 0.4.0 — 2026-06-01

MCP commands — wire the wokku-plugin Claude Code MCP server with one command. Pairs with wokku-cloud canonical backlog 1.3.

### Added

- `wokku mcp:install` — registers the Wokku MCP server in Claude Code using the active CLI token + API URL.
- `wokku mcp:switch` — re-pushes the current CLI token to the MCP config (after `auth:login` swapped accounts).
- `wokku mcp:logout` — removes the Wokku MCP server from Claude Code.

Shells out to `claude mcp add / remove` so we don't depend on Claude Code's internal config-file layout (it changes between versions). Aborts with a clear "install Claude Code first" error if the `claude` CLI isn't on PATH.

## 0.3.0 — 2026-05-31

Bundle v2 — boxes, shared addons (user-pick per box), and dedicated upgrades for PostgreSQL / MySQL / MongoDB / Redis. Pairs with wokku-cloud Phase 7 prep PRs #67–#73.

### Added
- `apps:create` gains `--box-size SIZE` (sleeping/small/medium/large/xlarge), `--shared pg,redis,...` (comma-separated shared engines to attach), `--dedicated-db postgres|mysql|mongodb`, `--dedicated-redis`. All optional — omitting them keeps the old free-tier default.
- `addons:shared:enable APP ENGINE` — attach a shared engine (Pg/Redis/Memcached/RabbitMQ/Meilisearch). Free plan limited to Pg+Redis.
- `addons:shared:disable APP ENGINE` — detach a shared engine + destroy its tenant data.
- `addons:dedicated:upgrade APP ENGINE` — upgrade to a dedicated container. Pg/Redis migrate from shared (data preserved). MySQL/MongoDB are fresh-create. Quota: 3 per plan; size follows the box size.
- `addons` listing now shows `kind: shared|dedicated` per row.

### Deprecated
- `addons:add` — kept for back-compat with wokku-cloud servers that haven't flipped `BUNDLE_V2_ENABLED=true` yet. When the server has bundle v2 on, this endpoint returns 410 Gone with guidance to use the new commands above.

### Requires
- wokku-cloud server-side support shipped 2026-05-31 (Phase 7 prep PRs #67–#73).

## 0.2.0 — 2026-05-06

Interactive shell over WebSocket: open a real PTY in your app's container, exec one-off commands, and connect to managed databases without leaving the terminal.

### Added
- `wokku enter APP` — interactive shell in the app's running container.
- `wokku ps:exec APP [-t|-T] -- CMD [ARGS...]` — run a command in a one-off container (Heroku-`run`-style; auto-detects TTY, `-t`/`-T` overrides).
- `wokku databases:connect DB` — interactive client for the managed database (psql / redis-cli / mysql via dokku's `<plugin>:connect`).

### Internals
- New `Wokku::CableClient` — thin `websocket-driver` wrapper, Bearer-token handshake on `/cable`.
- New `Wokku::PtySession` — local raw-mode PTY orchestration with SIGWINCH resize and guaranteed `cooked!` restore.
- Runtime dependency: `websocket-driver ~> 0.7`.

### Requires
- wokku-cloud server-side support shipped 2026-05-06 (Bearer auth on `ApplicationCable::Connection`, new `TerminalChannel` wire protocol with modes).

## 0.1.0 — 2026-05-04

First public release on RubyGems.

The wokku CLI was previously distributed as a tarball from `wokku.cloud/cli/wokku.tar.gz`. This is a fresh start under the `0.x` line — pre-1.0 means the surface may evolve as we gather feedback. Reach 1.0.0 once the API stabilizes.

### Features
- Apps: `apps`, `apps:create`, `apps:destroy`, `apps:info`
- Process: `ps:start/stop/restart/scale/rebuild`, `redeploy`
- Config: `config`, `config:set/get/unset`, `config:export` (.env-safe quoting)
- Domains: `domains`, `domains:add/remove/clear`, `certs:enable`
- Buildpacks: `buildpacks`, `buildpacks:add/remove/clear/set`
- Health checks: `checks`, `checks:set`
- Storage: `storage`, `storage:mount/unmount`
- Releases: `releases`, `rollback`
- Add-ons: `addons`, `addons:add`
- Templates: `templates`, `deploy`
- Activity: `activity`
- Logs: `logs` with `--follow` / `-f` streaming
- SSH keys: `ssh-keys`, `ssh-keys:add/remove`
- Servers: `servers`, `servers:info`, `servers:default`
- Databases: `databases`, `databases:create/destroy/info/link/unlink`
- One-off: `wokku run APP -- COMMAND` (in-container)
- Passthrough: `wokku do APP -- DOKKU_ARGS` (raw dokku command, audit-logged)
- Authentication: `auth:login`, `auth:logout`, `auth:whoami`
- Global flags: `--json` (machine-readable), `--quiet` / `-q`

### Distribution
- Install: `gem install wokku-cli` or `brew install johannesdwicahyo/tap/wokku`
- Source: <https://github.com/johannesdwicahyo/wokku-cli>
- Old `curl install.sh` flow continues to work (delegates to `gem install wokku-cli`).
