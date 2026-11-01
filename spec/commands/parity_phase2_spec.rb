# frozen_string_literal: true

RSpec.describe "parity phase 2 commands" do
  let(:fake) { FakeApiClient.new }

  it "previews:settings PATCHes on + database" do
    fake.stub(:patch, "/apps/shop/preview_settings", returns: { "preview_enabled" => true, "database_strategy" => "snapshot" })
    result = CliRunner.run("previews:settings", "shop", "--on", "--database", "snapshot", api: fake)
    expect(fake.calls.first.body).to eq(preview_enabled: true, database_strategy: "snapshot")
    expect(result.stdout).to match(/previews: on, database: snapshot/)
  end

  it "previews:settings aborts with no flags" do
    expect(CliRunner.run("previews:settings", "shop", api: fake).exit_code).not_to eq(0)
  end

  it "github:repos lists repos" do
    fake.stub(:get, "/github/repos", returns: [ { "full_name" => "acme/shop", "private" => true, "default_branch" => "main" } ])
    expect(CliRunner.run("github:repos", api: fake).stdout).to match(%r{acme/shop\s+private\s+main})
  end

  it "github:repos OWNER/REPO lists branches" do
    fake.stub(:get, "/github/repos?repo=acme%2Fshop", returns: { "repo" => "acme/shop", "branches" => %w[main staging] })
    expect(CliRunner.run("github:repos", "acme/shop", api: fake).stdout).to match(/main\n.*staging/m)
  end

  it "vitals:rotate-token prints the new token" do
    fake.stub(:post, "/apps/shop/vitals/rotate_token", returns: { "vitals_ingest_token" => "tok123" })
    expect(CliRunner.run("vitals:rotate-token", "shop", api: fake).stdout).to match(/New token: tok123/)
  end
end
