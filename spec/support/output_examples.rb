# frozen_string_literal: true

# Shared example: a read command, when invoked with --json, prints the
# raw API response as pretty JSON and yields exit 0.
RSpec.shared_examples "respects --json" do |command:, args: [], path:, fake_response:, api_method: :get|
  it "with --json prints raw API response as JSON" do
    fake = FakeApiClient.new
    fake.stub(api_method, path, returns: fake_response)
    result = CliRunner.run(command, *args, "--json", api: fake)
    expect(result.exit_code).to eq(0)
    expect(JSON.parse(result.stdout)).to eq(fake_response)
  end
end

# Shared example: a write command, when invoked with --quiet, produces
# empty stdout (status messages and hints suppressed) and yields exit 0.
RSpec.shared_examples "respects --quiet" do |command:, args:, path:, api_method: :post, fake_response: {}|
  it "with --quiet suppresses status messages" do
    fake = FakeApiClient.new
    fake.stub(api_method, path, returns: fake_response)
    result = CliRunner.run(command, *args, "--quiet", api: fake)
    expect(result.exit_code).to eq(0)
    expect(result.stdout.strip).to eq("")
  end
end
