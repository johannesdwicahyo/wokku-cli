# frozen_string_literal: true

# --- Cloudflare CDN proxy toggle ---

def print_cdn_state(enabled, note: nil)
  Wokku::Output.status "cdn: #{enabled ? 'on' : 'off'}"
  warn note if note
end

register "cdn", "Show Cloudflare CDN proxy state (usage: wokku cdn APP)" do
  id = ARGV.shift || abort("Usage: wokku cdn APP")
  data = api(:get, "/apps/#{id}")
  print_cdn_state(data.is_a?(Hash) && data["cloudflare_proxied"])
end

register "cdn:on", "Enable Cloudflare CDN proxy (usage: wokku cdn:on APP)" do
  id = ARGV.shift || abort("Usage: wokku cdn:on APP")
  data = api(:patch, "/apps/#{id}/cdn", { enabled: true })
  print_cdn_state(data.is_a?(Hash) ? data["enabled"] : true, note: "DNS propagation may take a minute.")
end

register "cdn:off", "Disable Cloudflare CDN proxy (usage: wokku cdn:off APP)" do
  id = ARGV.shift || abort("Usage: wokku cdn:off APP")
  data = api(:patch, "/apps/#{id}/cdn", { enabled: false })
  print_cdn_state(data.is_a?(Hash) ? data["enabled"] : false)
end
