# frozen_string_literal: true

RSpec.describe "wokku --help" do
  let(:expected_commands) do
    %w[
      activity
      addons addons:add
      apps apps:create apps:destroy apps:info
      auth:login auth:logout auth:whoami
      certs:enable
      checks checks:set
      config config:get config:set config:unset
      deploy
      domains domains:add domains:clear domains:remove
      logs
      ps:rebuild ps:restart ps:scale ps:start ps:stop
      redeploy
      releases rollback
      run
      templates
      version
    ]
  end

  it "lists every registered command" do
    result = CliRunner.run("--help")
    expect(result.exit_code).to eq(0)
    expected_commands.each do |cmd|
      expect(result.stdout).to include(cmd), "expected --help output to include '#{cmd}'"
    end
  end

  it "shows the version banner" do
    result = CliRunner.run("--help")
    expect(result.stdout).to match(/Wokku CLI v\d+\.\d+\.\d+/)
  end
end
