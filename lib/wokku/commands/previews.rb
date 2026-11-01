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

register "previews:settings", "Turn PR previews on/off and pick their database (usage: wokku previews:settings APP [--on|--off] [--database empty|snapshot|shared])" do
  id = ARGV.shift || abort("Usage: wokku previews:settings APP [--on|--off] [--database empty|snapshot|shared]")
  body = {}
  while arg = ARGV.shift
    case arg
    when "--on"       then body[:preview_enabled] = true
    when "--off"      then body[:preview_enabled] = false
    when "--database" then body[:database_strategy] = ARGV.shift || abort("--database needs empty, snapshot or shared")
    end
  end
  abort "Pass --on, --off and/or --database" if body.empty?
  data = api(:patch, "/apps/#{id}/preview_settings", body)
  data = {} unless data.is_a?(Hash)
  Wokku::Output.status "previews: #{data['preview_enabled'] ? 'on' : 'off'}, database: #{data['database_strategy']}"
end
