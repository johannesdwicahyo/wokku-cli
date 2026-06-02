# frozen_string_literal: true

# --- Core Web Vitals read (p75 per metric) ---

register "vitals", "Show p75 per Core Web Vital (usage: wokku vitals APP)" do
  id = ARGV.shift || abort("Usage: wokku vitals APP")
  data = api(:get, "/apps/#{id}/vitals")
  latest = data.is_a?(Hash) ? (data["latest"] || {}) : {}

  if latest.values.all?(&:nil?)
    Wokku::Output.status "no vitals collected yet"
    next
  end

  %w[CLS LCP INP FCP TTFB].each do |metric|
    row = latest[metric]
    if row.nil?
      Wokku::Output.status "#{metric}: —"
    else
      Wokku::Output.status "#{metric}: #{row['p75']} (n=#{row['sample_count']})"
    end
  end
end
