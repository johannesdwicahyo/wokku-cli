# frozen_string_literal: true

RSpec.describe "mcp commands" do
  before do
    # Token-required commands abort otherwise — stash a fake one.
    Wokku::Config.save("token" => "tk_test")
  end

  after { File.delete(Wokku::Config.file) if File.exist?(Wokku::Config.file) }

  describe "mcp:install" do
    it "aborts when `claude` CLI is unavailable" do
      allow_any_instance_of(Kernel).to receive(:system).with("command -v claude >/dev/null 2>&1").and_return(false)
      result = CliRunner.run("mcp:install")
      expect(result.exit_code).not_to eq(0)
      expect(result.stderr).to include("claude` CLI is not installed")
    end

    it "removes any prior entry then re-adds with the current token" do
      allow_any_instance_of(Kernel).to receive(:system).with("command -v claude >/dev/null 2>&1").and_return(true)
      calls = []
      allow_any_instance_of(Kernel).to receive(:system) do |_, *args|
        calls << args
        true
      end
      result = CliRunner.run("mcp:install")
      expect(result.exit_code).to eq(0)
      remove_call = calls.find { |a| a.first&.include?("claude mcp remove") }
      add_call    = calls.find { |a| a.include?("add") }
      expect(remove_call).not_to be_nil
      # The endpoint is fixed to wokku.cloud in the plugin, so the CLI
      # only passes the token — never a WOKKU_API_URL override.
      expect(add_call).to include("WOKKU_API_TOKEN=tk_test")
      expect(add_call.none? { |a| a.to_s.start_with?("WOKKU_API_URL=") }).to be(true)
    end
  end

  describe "mcp:logout" do
    it "calls `claude mcp remove wokku`" do
      allow_any_instance_of(Kernel).to receive(:system).with("command -v claude >/dev/null 2>&1").and_return(true)
      called_args = nil
      allow_any_instance_of(Kernel).to receive(:system) do |_, *args|
        called_args = args if args.include?("remove")
        true
      end
      result = CliRunner.run("mcp:logout")
      expect(result.exit_code).to eq(0)
      expect(called_args).to include("remove", "wokku")
    end
  end

  describe "mcp:switch" do
    it "is install under the hood — re-pushes the current token" do
      allow_any_instance_of(Kernel).to receive(:system).with("command -v claude >/dev/null 2>&1").and_return(true)
      add_called = false
      allow_any_instance_of(Kernel).to receive(:system) do |_, *args|
        add_called = true if args.include?("add")
        true
      end
      result = CliRunner.run("mcp:switch")
      expect(result.exit_code).to eq(0)
      expect(add_called).to be true
    end
  end
end
