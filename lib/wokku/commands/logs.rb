# frozen_string_literal: true

# --- Logs ---
register "logs", "View logs (usage: wokku logs APP [--lines N])" do
  id = ARGV.shift || abort("Usage: wokku logs APP")
  lines = 100
  while arg = ARGV.shift
    lines = ARGV.shift.to_i if arg == "--lines"
  end
  data = api(:get, "/apps/#{id}/logs?lines=#{lines}")
  if data.is_a?(Array)
    data.each { |l| puts l }
  elsif data.is_a?(Hash) && data["logs"]
    puts data["logs"]
  else
    puts_json data
  end
end
