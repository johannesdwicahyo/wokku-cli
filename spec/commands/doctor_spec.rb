# frozen_string_literal: true

RSpec.describe "doctor and ai commands" do
  let(:fake) { FakeApiClient.new }

  it "doctor prints the diagnosis" do
    fake.stub(:get, "/doctor", returns: { "auth" => "ok", "checks" => [] })
    expect(CliRunner.run("doctor", api: fake).stdout).to include("auth")
  end

  it "ai:diagnose uses the given deploy" do
    fake.stub(:post, "/ai/diagnose", returns: { "diagnosis" => "missing gem" })
    result = CliRunner.run("ai:diagnose", "a", "d1", api: fake)
    expect(fake.calls.last.body).to eq(deploy_id: "d1")
    expect(result.stdout).to include("missing gem")
  end

  it "ai:diagnose defaults to the latest deploy" do
    fake.stub(:get, "/apps/a/deploys", returns: [ { "id" => "d9" }, { "id" => "d8" } ])
    fake.stub(:post, "/ai/diagnose", returns: { "diagnosis" => "x" })
    CliRunner.run("ai:diagnose", "a", api: fake)
    expect(fake.calls.last.body).to eq(deploy_id: "d9")
  end
end
