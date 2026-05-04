# Changelog

## 3.0.0 — 2026-05-04

### Breaking
- Distribution moved from `curl install.sh` tarball to RubyGems (`gem install wokku-cli`)
- Source repo moved from `wokku-cloud/cli/` (private) to `johannesdwicahyo/wokku-cli` (public, MIT)

### Migration
- Existing `curl install.sh` users get the new `gem install` flow automatically (install.sh updated)
- Brew users: `brew upgrade wokku` pulls v3.0.0 from RubyGems
- Old tarball endpoints (`wokku.cloud/cli/wokku.tar.gz`, `/cli/wokku`, `/cli/lib/wokku/:name`) stay live for ~3 months serving frozen v2.x

## Earlier history

See `git log` — releases prior to 3.0.0 were tagged inside the wokku-cloud repo and distributed via tarball.
