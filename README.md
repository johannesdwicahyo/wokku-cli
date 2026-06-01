# wokku-cli

CLI for [Wokku Cloud](https://wokku.cloud) — deploy and manage apps, databases, domains, and SSH keys.

> **Wokku Cloud only.** This CLI talks to the Wokku REST API, which ships only with the managed Wokku Cloud product. The open-source Wokku web UI ([github.com/johannesdwicahyo/wokku](https://github.com/johannesdwicahyo/wokku)) does not expose `/api/v1`, so the CLI cannot point at a self-hosted Wokku install. Self-host users should use the web UI directly, or `ssh dokku@your-host` for command-line operations.

## Install

```sh
gem install wokku-cli
```

Or via Homebrew:

```sh
brew install johannesdwicahyo/tap/wokku
```

## Quick start

```sh
wokku auth:login
wokku apps
wokku apps:create myapp
wokku ps:restart myapp
wokku logs myapp -f
```

## Commands

Run `wokku --help` for the full list. ~39 first-class commands today, grouped:

- **Apps:** `apps`, `apps:create`, `apps:destroy`, `apps:info`, `apps:transfer`
- **Process:** `ps`, `ps:start/stop/restart/scale/rebuild`, `redeploy`
- **Config:** `config`, `config:set`, `config:get`, `config:unset`, `config:export`
- **Domains + SSL:** `domains`, `domains:add/remove/clear`, `certs:enable`, `certs:disable`
- **Databases:** `databases`, `databases:create/destroy/link/unlink/info`, `backups`, `backups:create/restore`
- **SSH keys:** `ssh-keys`, `ssh-keys:add/remove`
- **Servers:** `servers`, `servers:info`, `servers:default` (multi-Dokku-host installs)
- **Teams:** `teams`, `teams:members`, `teams:invite`, `teams:remove`
- **Logs:** `wokku logs APP --follow [--tail N]`
- **Run / passthrough:** `wokku run APP -- COMMAND` (one-off in a fresh container), `wokku do APP -- DOKKU_ARGS` (arbitrary `dokku` CLI passthrough)

### Parity with Dokku

`wokku do` is the bridge for the ~110 Dokku subcommands not yet first-classed here. Anything `dokku <something> APP` does, `wokku do APP -- <something>` does too — same exit code, same stdout.

If you find yourself running the same `wokku do` invocation repeatedly, open an issue — that's the queue for promoting commands to first-class status.

## Global flags

- `--json` — machine-readable JSON output (read commands only)
- `--quiet` / `-q` — suppress success messages and hints
- `--server NAME` — target a specific Dokku host on multi-server installs (default: your account's primary)

## Configuration

Set once and forget:

```sh
export WOKKU_API_TOKEN=...   # from wokku.cloud/dashboard/profile
```

`WOKKU_API_URL` defaults to `https://wokku.cloud/api/v1` and shouldn't need to change.

## What's New in v0.2.0 (May 2026)

- `apps:transfer` for moving an app between teams
- `--quiet` flag now also suppresses progress bars (not just success lines) — friendlier in scripts
- `wokku do` exit codes pass through correctly when wrapped in pipelines (was previously masked to 0)
- Multi-server defaults — `wokku servers:default` persists per-account, not per-shell

## License

MIT — see [LICENSE](LICENSE).
