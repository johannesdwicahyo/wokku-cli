# frozen_string_literal: true

require "time"
require "uri"

# --- Incidents & alert mutes ---
# Command files are required at top level, so helper names are prefixed to stay out of the global namespace.
def incidents_rows(list)
  list.map do |x|
    { "id" => x["id"], "subject" => x["app_name"] || "server #{x['server_id']}", "reason" => x["reason"],
      "started" => x["started_at"].to_s[0..18], "status" => x["open"] ? "OPEN" : "resolved after #{x['duration_seconds']}s" }
  end
end

def incidents_flag_value(name)
  i = ARGV.index(name) or return nil
  ARGV.delete_at(i)
  ARGV.delete_at(i) || abort("Missing value for #{name}")
end

register "incidents", "List incidents (usage: wokku incidents [--all] [--app APP])" do
  query = { state: ARGV.delete("--all") ? "all" : "open" }
  app = incidents_flag_value("--app")
  query[:app_id] = app if app
  data = api(:get, "/incidents?#{URI.encode_www_form(query)}")
  Wokku::Output.render(data) do |d|
    next puts_json(d) unless d.is_a?(Array)
    d.empty? ? puts("No incidents.") : table(incidents_rows(d))
  end
end

register "incidents:info", "Show one incident (usage: wokku incidents:info ID)" do
  id = ARGV.shift || abort("Usage: wokku incidents:info ID")
  data = api(:get, "/incidents/#{id}")
  Wokku::Output.render(data) { |d| puts_json d }
end

register "alerts:mutes", "List your push alert mutes (usage: wokku alerts:mutes)" do
  data = api(:get, "/alert_mutes")
  Wokku::Output.render(data) do |d|
    next puts_json(d) unless d.is_a?(Array)
    next puts("No mutes.") if d.empty?
    table(d.map { |m| { "id" => m["id"], "app" => m["app_name"] || "(all apps)", "event" => m["event"] || "(all events)", "until" => m["until"].to_s[0..18].then { |u| u.empty? ? "removed" : u } } })
  end
end

MUTE_UNITS = { "m" => 60, "h" => 3600, "d" => 86_400 }.freeze

register "alerts:mute", "Mute push alerts on your phone (usage: wokku alerts:mute [--app APP] [--event EVENT] [--for 1h|8h|1d])" do
  usage = "Usage: wokku alerts:mute [--app APP] [--event EVENT] [--for 1h|8h|1d]"
  body = { app_id: incidents_flag_value("--app"), event: incidents_flag_value("--event") }.compact
  abort "#{usage} (give --app and/or --event)" if body.empty?
  if (span = incidents_flag_value("--for"))
    m = span.match(/\A(\d+)([mhd])\z/) || abort("#{usage} (--for looks like 30m, 8h or 1d)")
    body[:until] = (Time.now + m[1].to_i * MUTE_UNITS[m[2]]).utc.iso8601
  end
  data = api(:post, "/alert_mutes", body)
  Wokku::Output.render(data) { |d| Wokku::Output.status "Muted (#{d['id']})." }
end

register "alerts:unmute", "Remove a push alert mute (usage: wokku alerts:unmute ID)" do
  id = ARGV.shift || abort("Usage: wokku alerts:unmute ID")
  api(:delete, "/alert_mutes/#{id}")
  Wokku::Output.status "Unmuted."
end
