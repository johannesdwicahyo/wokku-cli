# frozen_string_literal: true

# --- HTTPS redirect toggle ---

def print_https_state(enabled)
  Wokku::Output.status "https redirect: #{enabled ? 'on' : 'off'}"
end

register "https", "Show HTTPS redirect state (usage: wokku https APP)" do
  id = ARGV.shift || abort("Usage: wokku https APP")
  data = api(:get, "/apps/#{id}")
  print_https_state(data.is_a?(Hash) && data["https_redirect"])
end

register "https:on", "Enable HTTPS redirect (usage: wokku https:on APP)" do
  id = ARGV.shift || abort("Usage: wokku https:on APP")
  data = api(:patch, "/apps/#{id}/https", { enabled: true })
  print_https_state(data.is_a?(Hash) ? data["enabled"] : true)
end

register "https:off", "Disable HTTPS redirect (usage: wokku https:off APP)" do
  id = ARGV.shift || abort("Usage: wokku https:off APP")
  data = api(:patch, "/apps/#{id}/https", { enabled: false })
  print_https_state(data.is_a?(Hash) ? data["enabled"] : false)
end
