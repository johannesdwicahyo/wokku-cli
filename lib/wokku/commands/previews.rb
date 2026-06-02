# frozen_string_literal: true

# --- PR previews ---

register "previews", "List PR preview apps (usage: wokku previews APP)" do
  id = ARGV.shift || abort("Usage: wokku previews APP")
  data = api(:get, "/apps/#{id}/previews")
  rows = data.is_a?(Array) ? data : []
  if rows.empty?
    Wokku::Output.status "no preview apps"
    next
  end
  rows.each do |p|
    line = "##{p['pr_number']}  #{p['branch']}  #{p['status']}  #{p['name']}"
    line += "  #{p['url']}" if p["url"]
    Wokku::Output.status line
  end
end

register "previews:destroy", "Queue cleanup of a PR preview (usage: wokku previews:destroy APP PR_NUMBER)" do
  id  = ARGV.shift || abort("Usage: wokku previews:destroy APP PR_NUMBER")
  pr  = ARGV.shift || abort("Missing PR_NUMBER")
  data = api(:delete, "/apps/#{id}/previews/#{pr}")
  message = data.is_a?(Hash) ? data["message"] : nil
  Wokku::Output.status(message || "Preview destroy queued.")
end
