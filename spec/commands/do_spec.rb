# frozen_string_literal: true

RSpec.describe "wokku do" do
  let(:fake) { FakeApiClient.new }

  it "POSTs /apps/:id/dokku with args array (app-scoped)" do
    fake.stub(:post, "/apps/myapp/dokku", returns: { "stdout" => "web.1: running", "stderr" => "", "exit_code" => 0 })
    result = CliRunner.run("do", "myapp", "--", "ps:list", api: fake)
    expect(result.exit_code).to eq(0)
    expect(result.stdout).to include("web.1: running")
    expect(fake.calls.first.body).to eq(args: ["ps:list"], force: false)
  end

  it "POSTs /servers/:id/dokku when --server is given" do
    fake.stub(:post, "/servers/1/dokku", returns: { "stdout" => "v0.34.0", "stderr" => "", "exit_code" => 0 })
    result = CliRunner.run("do", "--server", "1", "--", "version", api: fake)
    expect(result.exit_code).to eq(0)
    expect(result.stdout).to include("v0.34.0")
  end

  it "passes force: true when --force given" do
    fake.stub(:post, "/apps/myapp/dokku", returns: { "stdout" => "ok", "stderr" => "", "exit_code" => 0 })
    CliRunner.run("do", "myapp", "--force", "--", "plugin:install", "foo", api: fake)
    expect(fake.calls.first.body).to eq(args: ["plugin:install", "foo"], force: true)
  end

  it "propagates non-zero exit code from dokku" do
    fake.stub(:post, "/apps/myapp/dokku", returns: { "stdout" => "", "stderr" => "boom", "exit_code" => 7 })
    result = CliRunner.run("do", "myapp", "--", "apps:report", "missing", api: fake)
    expect(result.exit_code).to eq(7)
  end

  it "aborts when -- separator is missing" do
    result = CliRunner.run("do", "myapp", "ps:list", api: fake)
    expect(result.exit_code).not_to eq(0)
    expect(result.stderr + result.stdout).to match(/separator/)
  end

  it "aborts when both APP and --server are given" do
    result = CliRunner.run("do", "myapp", "--server", "1", "--", "ps:list", api: fake)
    expect(result.exit_code).not_to eq(0)
    expect(result.stderr + result.stdout).to match(/not both/)
  end

  it "aborts when neither APP nor --server given" do
    result = CliRunner.run("do", "--", "version", api: fake)
    expect(result.exit_code).not_to eq(0)
  end

  it "accepts UUID just as well as name" do
    uuid = "00000000-0000-0000-0000-000000000001"
    fake.stub(:post, "/apps/#{uuid}/dokku", returns: { "stdout" => "ok", "stderr" => "", "exit_code" => 0 })
    result = CliRunner.run("do", uuid, "--", "ps:list", api: fake)
    expect(result.exit_code).to eq(0)
  end
end
