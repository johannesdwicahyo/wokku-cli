# frozen_string_literal: true

require "webmock/rspec"
require "tmpdir"
require "stringio"

# Isolate config from the user's real ~/.wokku
ENV["WOKKU_CONFIG_DIR"] ||= Dir.mktmpdir("wokku-spec-config")

# Load CLI in-process via the gem-style entry point.
require_relative "../lib/wokku"

Dir[File.join(__dir__, "support/**/*.rb")].each { |f| require f }

RSpec.configure do |c|
  c.expect_with(:rspec) { |e| e.syntax = :expect }
  c.disable_monkey_patching!
  c.order = :random
  Kernel.srand c.seed

  c.before(:each) do
    WebMock.disable_net_connect!
    Wokku.api_client = nil  # reset cached default client between examples
    Wokku.json = nil
    Wokku.quiet = nil
  end
end
