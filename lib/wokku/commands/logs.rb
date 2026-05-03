# frozen_string_literal: true

# --- Logs ---
register "logs", "View logs (usage: wokku logs APP [--lines N])" do
  id = ARGV.shift || abort("Usage: wokku logs APP")
  lines = 100
  while arg = ARGV.shift
    lines = ARGV.shift.to_i if arg == "--lines"
  end
  data = api(:get, "/apps/#{id}/logs?lines=#{lines}")
  Wokku::Output.render(data) do |d|
    if d.is_a?(Array)
      d.each { |l| puts l }
    elsif d.is_a?(Hash) && d["logs"]
      puts d["logs"]
    else
      puts_json d
    end
  end
end
