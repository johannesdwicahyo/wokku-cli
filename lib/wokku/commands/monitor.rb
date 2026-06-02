# frozen_string_literal: true

# --- App HTTP request monitor (req-rate, latency, error %) ---

register "monitor", "Show request totals and slow URLs (usage: wokku monitor APP)" do
  id = ARGV.shift || abort("Usage: wokku monitor APP")
  data = api(:get, "/apps/#{id}/monitor")
  totals = data.is_a?(Hash) ? (data["totals"] || {}) : {}

  if totals["req_count"].to_i.zero?
    Wokku::Output.status "no requests in the last 24h"
    next
  end

  Wokku::Output.status "req: #{totals['req_count']}"
  Wokku::Output.status "rpm: #{totals['rpm']}"
  Wokku::Output.status "p50: #{totals['p50_ms']}ms"
  Wokku::Output.status "p95: #{totals['p95_ms']}ms"
  Wokku::Output.status "error rate: #{((totals['error_rate'].to_f * 100).round(2))}%"

  slow = Array(data["recent_slow"]).first(3)
  if slow.any?
    Wokku::Output.status ""
    Wokku::Output.status "top slow:"
    slow.each do |s|
      Wokku::Output.status "  #{s['method']} #{s['path']} #{s['response_time_ms']}ms (#{s['status']})"
    end
  end
end
