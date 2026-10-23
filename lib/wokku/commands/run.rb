# frozen_string_literal: true

# --- One-off command in an ephemeral container ---
# apps.run is async (202 {run_id}); poll runs.show to a terminal status.
register "run", "Run a one-off command (usage: wokku run APP -- COMMAND [ARGS...], e.g. wokku run APP -- bin/rails db:migrate)" do
  id = ARGV.shift || abort("Usage: wokku run APP -- COMMAND")
  ARGV.shift if ARGV.first == "--"
  cmd = ARGV.join(" ")
  ARGV.clear
  abort "Missing command. Example: wokku run APP -- bin/rails db:migrate" if cmd.strip.empty?
  started = api(:post, "/apps/#{id}/run", { command: cmd })
  run_id = started.is_a?(Hash) && started["run_id"]
  abort "Unexpected response: #{started.inspect[0..200]}" unless run_id
  $stderr.puts "Run #{run_id} started — check later with: wokku run:status #{id} #{run_id}"
  final = poll_until("/apps/#{id}/runs/#{run_id}", attempts: 300, interval: 2) { |d| d.is_a?(Hash) && %w[succeeded failed].include?(d["status"].to_s) }
  abort "Still running after 10 minutes. Check: wokku run:status #{id} #{run_id}" unless final
  puts final["output"] if final["output"]
  $stderr.puts final["error"] if final["error"]
  exit (final["exit_code"] || (final["status"] == "succeeded" ? 0 : 1)).to_i
end

register "run:status", "Show a one-off run (usage: wokku run:status APP RUN_ID)" do
  id = ARGV.shift || abort("Usage: wokku run:status APP RUN_ID")
  run_id = ARGV.shift || abort("Missing RUN_ID")
  data = api(:get, "/apps/#{id}/runs/#{run_id}")
  Wokku::Output.render(data) { |d| puts_json d }
end
