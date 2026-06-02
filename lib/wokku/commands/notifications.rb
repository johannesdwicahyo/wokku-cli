# frozen_string_literal: true

# --- Notifications (team-scoped channels) ---

register "notifications", "List your notifications (usage: wokku notifications)" do
  data = api(:get, "/notifications")
  rows = data.is_a?(Array) ? data : []
  if rows.empty?
    Wokku::Output.status "no notifications"
    next
  end
  rows.each do |n|
    events = Array(n["events"]).join(",")
    Wokku::Output.status "#{n['id']}  #{n['channel']}  #{events}"
  end
end

register "notifications:add",
         "Add a notification (email only in v1). Usage: wokku notifications:add --team TEAM_ID --channel email --events EVENT1,EVENT2" do
  team_id = nil
  channel = nil
  events  = nil
  while arg = ARGV.shift
    case arg
    when "--team"     then team_id = ARGV.shift
    when "--channel"  then channel = ARGV.shift
    when "--events"   then events  = ARGV.shift
    end
  end
  abort "Missing --team TEAM_ID"         if team_id.nil? || team_id.empty?
  abort "Missing --channel email"        if channel.nil? || channel.empty?
  abort "v1 only supports --channel email (use the dashboard for slack/webhook/etc.)" unless channel == "email"
  abort "Missing --events. Example: --events deploy_succeeded,deploy_failed" if events.nil? || events.empty?

  data = api(:post, "/notifications", {
    team_id: team_id,
    channel: channel,
    events: events.split(",").map(&:strip)
  })
  id = data.is_a?(Hash) ? data["id"] : nil
  Wokku::Output.status "Notification added#{id ? " (id=#{id})" : ''}."
end

register "notifications:remove", "Remove a notification (usage: wokku notifications:remove NOTIFICATION_ID)" do
  id = ARGV.shift || abort("Usage: wokku notifications:remove NOTIFICATION_ID")
  data = api(:delete, "/notifications/#{id}")
  message = data.is_a?(Hash) ? data["message"] : nil
  Wokku::Output.status(message || "Notification removed.")
end
