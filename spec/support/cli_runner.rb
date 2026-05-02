# frozen_string_literal: true

# Runs the wokku CLI in-process with stdout/stderr/exit captured.
# Usage:
#   result = CliRunner.run("apps", api: fake_client, stdin: "y\n")
#   expect(result.stdout).to include("...")
#   expect(result.exit_code).to eq(0)
module CliRunner
  Result = Struct.new(:stdout, :stderr, :exit_code, keyword_init: true)

  module_function

  def run(*args, api: nil, stdin: "")
    Wokku.api_client = api if api

    captured_out = StringIO.new
    captured_err = StringIO.new
    real_stdin = $stdin
    $stdin = StringIO.new(stdin)

    exit_code = 0
    original_stdout = $stdout
    original_stderr = $stderr
    $stdout = captured_out
    $stderr = captured_err

    begin
      exit_code = dispatch(args.flatten.map(&:to_s))
    rescue SystemExit => e
      exit_code = e.status || 1
    ensure
      $stdout = original_stdout
      $stderr = original_stderr
      $stdin = real_stdin
      Wokku.api_client = nil
    end

    Result.new(stdout: captured_out.string, stderr: captured_err.string, exit_code: exit_code)
  end
end
