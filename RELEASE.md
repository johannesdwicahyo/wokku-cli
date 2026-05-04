# Release process

Manual local publish. Matches the standing pattern for other gems we maintain.

## Steps

1. **Bump version** in `lib/wokku/version.rb` (and add a section to `CHANGELOG.md`).
2. **Run tests + smoke**:
   ```sh
   bundle exec rspec
   gem build wokku-cli.gemspec
   ```
3. **Publish to RubyGems** (uses `~/.gem/credentials`; account requires MFA):
   ```sh
   gem push wokku-cli-*.gem
   ```
4. **Tag the release**:
   ```sh
   git tag v$(ruby -Ilib -e 'require "wokku/version"; puts Wokku::VERSION')
   git push --tags
   ```
5. **Update Homebrew tap formula** at `johannesdwicahyo/homebrew-tap/Formula/wokku.rb`:
   - Bump `version` and `url` to the new gem
   - Compute new `sha256`: `curl -sL https://rubygems.org/downloads/wokku-cli-X.Y.Z.gem | shasum -a 256`
   - Open a PR (or push directly if you maintain the tap)

## Versioning

Standard semver. Major bumps signal breaking changes (new required Ruby version, removed commands, distribution changes).
