# frozen_string_literal: true

RSpec.describe "run command" do
  let(:fake) { FakeApiClient.new }

  it "POSTs /apps/:id/run with command joined and prints output" do
    fake.stub(:post, "/apps/5/run", returns: { "output" => "hello\n", "exit_code" => 0 })
    result = CliRunner.run("run", "5", "--", "echo", "hello", api: fake)
    expect(result.exit_code).to eq(0)
    expect(result.stdout).to include("hello")
    expect(fake.calls.first.body).to eq(command: "echo hello")
  end

  it "aborts when no command given" do
    result = CliRunner.run("run", "5", "--", api: fake)
    expect(result.exit_code).not_to eq(0)
  end

  it "propagates non-zero exit code from the remote command" do
    fake.stub(:post, "/apps/5/run", returns: { "output" => "", "exit_code" => 3 })
    result = CliRunner.run("run", "5", "--", "false", api: fake)
    expect(result.exit_code).to eq(3)
  end
end
