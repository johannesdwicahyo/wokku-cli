# frozen_string_literal: true

# Verifies that an app-scoped command interpolates its first arg
# straight into the API path (no client-side ID resolution / mangling).
# AppRecord.lookup! on the server handles UUID-or-name.
RSpec.shared_examples "passes APP through verbatim" do |command:, path_pattern:, api_method: :get|
  it "accepts a UUID and a name interchangeably" do
    %w[my-app 00000000-0000-0000-0000-000000000001].each do |arg|
      fake = FakeApiClient.new
      expected_path = path_pattern.sub("APP", arg)
      fake.stub(api_method, expected_path, returns: [])
      CliRunner.run(command, arg, api: fake)
      expect(fake.calls.first.path).to eq(expected_path),
        "expected #{command} to call #{expected_path}, got #{fake.calls.first.path}"
    end
  end
end
