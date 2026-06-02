# frozen_string_literal: true

# --- Maintenance mode toggle ---

def print_maintenance_state(enabled)
  Wokku::Output.status "maintenance: #{enabled ? 'on' : 'off'}"
end

register "maintenance", "Show maintenance mode state (usage: wokku maintenance APP)" do
  id = ARGV.shift || abort("Usage: wokku maintenance APP")
  data = api(:get, "/apps/#{id}")
  print_maintenance_state(data.is_a?(Hash) && data["maintenance_enabled"])
end

register "maintenance:on", "Enable maintenance mode (usage: wokku maintenance:on APP)" do
  id = ARGV.shift || abort("Usage: wokku maintenance:on APP")
  data = api(:patch, "/apps/#{id}/maintenance", { enabled: true })
  print_maintenance_state(data.is_a?(Hash) ? data["enabled"] : true)
end

register "maintenance:off", "Disable maintenance mode (usage: wokku maintenance:off APP)" do
  id = ARGV.shift || abort("Usage: wokku maintenance:off APP")
  data = api(:patch, "/apps/#{id}/maintenance", { enabled: false })
  print_maintenance_state(data.is_a?(Hash) ? data["enabled"] : false)
end
