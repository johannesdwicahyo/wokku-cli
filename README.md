# wokku-cli

CLI for [Wokku](https://wokku.cloud) — deploy and manage apps, databases, domains, and SSH keys on Wokku.cloud or self-hosted Wokku servers.

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

Run `wokku --help` for the full list. Highlights:

- **Apps:** `apps`, `apps:create`, `apps:destroy`, `apps:info`
- **Process:** `ps:start/stop/restart/scale/rebuild`, `redeploy`
- **Config:** `config`, `config:set`, `config:get`, `config:unset`, `config:export`
- **Domains:** `domains`, `domains:add/remove/clear`, `certs:enable`
- **Databases:** `databases`, `databases:create/destroy/link/unlink/info`
- **SSH keys:** `ssh-keys`, `ssh-keys:add/remove`
- **Servers:** `servers`, `servers:info`, `servers:default`
- **Logs:** `wokku logs APP --follow`
- **Run / passthrough:** `wokku run APP -- COMMAND`, `wokku do APP -- DOKKU_ARGS`

## Global flags

- `--json` — machine-readable JSON output (read commands)
- `--quiet` / `-q` — suppress success messages and hints

## License

MIT — see [LICENSE](LICENSE).
