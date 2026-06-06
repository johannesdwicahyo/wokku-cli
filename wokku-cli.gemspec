require_relative "lib/wokku/version"

Gem::Specification.new do |s|
  s.name          = "wokku-cli"
  s.version       = Wokku::VERSION
  s.authors       = ["Johannes Dwicahyo"]
  s.email         = ["johannesdwicahyo@gmail.com"]
  s.summary       = "Wokku CLI — manage your Wokku apps from the terminal"
  s.description   = "Deploy and manage apps, databases, domains, and SSH keys on Wokku.cloud (managed cloud)."
  s.homepage      = "https://wokku.cloud"
  s.license       = "MIT"
  s.required_ruby_version = ">= 3.2.0"

  s.files         = Dir["lib/**/*", "exe/*", "README.md", "LICENSE", "CHANGELOG.md"]
  s.bindir        = "exe"
  s.executables   = ["wokku"]
  s.require_paths = ["lib"]

  s.add_dependency "websocket-driver", "~> 0.7"

  s.metadata = {
    "homepage_uri"          => "https://wokku.cloud",
    "source_code_uri"       => "https://github.com/johannesdwicahyo/wokku-cli",
    "bug_tracker_uri"       => "https://github.com/johannesdwicahyo/wokku-cli/issues",
    "changelog_uri"         => "https://github.com/johannesdwicahyo/wokku-cli/blob/main/CHANGELOG.md",
    "rubygems_mfa_required" => "true"
  }
end
