# frozen_string_literal: true

# --- One-off command in an ephemeral container ---
register "run", "Run a one-off command (usage: wokku run APP -- COMMAND [ARGS...])" do
  id = ARGV.shift || abort("Usage: wokku run APP -- COMMAND")
  ARGV.shift if ARGV.first == "--"
  cmd = ARGV.join(" ")
  ARGV.clear
  abort "Missing command. Example: wokku run APP -- bin/rails console" if cmd.strip.empty?
  data = api(:post, "/apps/#{id}/run", { command: cmd })
  puts data["output"] if data.is_a?(Hash) && data["output"]
  exit (data["exit_code"] || 0).to_i if data.is_a?(Hash) && data.key?("exit_code")
end
