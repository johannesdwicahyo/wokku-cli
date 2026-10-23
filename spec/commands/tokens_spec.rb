# frozen_string_literal: true

RSpec.describe "tokens commands" do
  let(:fake) { FakeApiClient.new }

  it "tokens lists tokens" do
    fake.stub(:get, "/auth/tokens", returns: [ { "id" => "t1", "name" => "ci", "last_used_at" => nil } ])
    expect(CliRunner.run("tokens", api: fake).stdout).to include("ci")
  end

  it "tokens:create prints the new token once" do
    fake.stub(:post, "/auth/tokens", returns: { "id" => "t2", "name" => "laptop", "token" => "wk_secret" })
    result = CliRunner.run("tokens:create", "laptop", api: fake)
    expect(fake.calls.last.body).to eq(name: "laptop")
    expect(result.stdout).to include("wk_secret")
  end

  it "tokens:revoke DELETEs" do
    fake.stub(:delete, "/auth/tokens/t1", returns: {})
    expect(CliRunner.run("tokens:revoke", "t1", api: fake).exit_code).to eq(0)
  end
end
