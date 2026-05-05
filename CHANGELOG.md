# Changelog

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
