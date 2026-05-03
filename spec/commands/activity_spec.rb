# frozen_string_literal: true

RSpec.describe "activity command" do
  let(:fake) { FakeApiClient.new }

  it "lists recent activity" do
    fake.stub(:get, "/activities?limit=20", returns: [{ "created_at" => "2026-05-01T00:00:00Z", "action" => "deploy", "target_name" => "alpha" }])
    result = CliRunner.run("activity", api: fake)
    expect(result.exit_code).to eq(0)
    expect(result.stdout).to include("deploy").and include("alpha")
  end

  include_examples "respects --json",
    command: "activity",
    path: "/activities?limit=20",
    fake_response: [{ "created_at" => "2026-05-01T00:00:00Z", "action" => "deploy", "target_name" => "alpha" }]
end
