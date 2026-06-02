# frozen_string_literal: true

# --- Database monitor (connections, cache hit, slow queries) ---

register "db:monitor", "Show database connections, cache hit, size, and slow queries (usage: wokku db:monitor DB)" do
  id = ARGV.shift || abort("Usage: wokku db:monitor DB")
  data = api(:get, "/databases/#{id}/monitor")

  if !data.is_a?(Hash) || data["recorded_at"].nil?
    Wokku::Output.status "no stats collected yet"
    next
  end

  size_mb = data["db_size_bytes"] ? (data["db_size_bytes"].to_f / (1024 * 1024)).round(2) : nil
  Wokku::Output.status "conns: #{data['active_connections']} / #{data['max_connections']}"
  Wokku::Output.status "size: #{size_mb} MB" if size_mb
  Wokku::Output.status "cache hit: #{(data['cache_hit_ratio'].to_f * 100).round(2)}%"

  queries = Array(data["top_queries"]).first(5)
  if queries.any?
    Wokku::Output.status ""
    Wokku::Output.status "top queries:"
    queries.each do |q|
      qstr = q["query"].to_s.gsub(/\s+/, " ").strip
      qstr = qstr[0, 80] + "…" if qstr.length > 80
      Wokku::Output.status "  #{qstr}"
      Wokku::Output.status "    calls=#{q['calls']} mean=#{q['mean_ms']}ms total=#{q['total_ms']}ms"
    end
  end
end
