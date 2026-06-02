# frozen_string_literal: true

# --- App runtime metrics (CPU / memory) ---

register "metrics", "Show latest CPU + memory for an app (usage: wokku metrics APP)" do
  id = ARGV.shift || abort("Usage: wokku metrics APP")
  data = api(:get, "/apps/#{id}/metrics")
  minute = data.is_a?(Hash) ? Array(data["minute"]) : []

  if minute.empty?
    Wokku::Output.status "no metrics collected yet"
    next
  end

  last = minute.last
  cpu = last["cpu_pct"]
  mem = last["memory_mb"]
  limit = last["memory_limit_mb"]
  Wokku::Output.status "cpu: #{cpu}%"
  Wokku::Output.status "mem: #{mem} MB#{limit ? " / #{limit} MB" : ''}"
end
