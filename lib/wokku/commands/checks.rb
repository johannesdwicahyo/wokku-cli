# frozen_string_literal: true

# --- Health checks ---
register "checks", "Show Dokku health check config (usage: wokku checks APP)" do
  id = ARGV.shift || abort("Usage: wokku checks APP")
  data = api(:get, "/apps/#{id}/checks")
  puts_json data
end

register "checks:set", "Update health check settings (usage: wokku checks:set APP [--enabled BOOL] [--wait N] [--timeout N] [--attempts N] [--path PATH])" do
  id = ARGV.shift || abort("Usage: wokku checks:set APP [flags]")
  body = {}
  while arg = ARGV.shift
    case arg
    when "--enabled"   then body[:enabled]  = ARGV.shift
    when "--wait"      then body[:wait]     = ARGV.shift
    when "--timeout"   then body[:timeout]  = ARGV.shift
    when "--attempts"  then body[:attempts] = ARGV.shift
    when "--path"      then body[:path]     = ARGV.shift
    end
  end
  abort "No flags given. Try --enabled true, --path /healthz, --wait 5, etc." if body.empty?
  api(:put, "/apps/#{id}/checks", body)
  puts "Health check settings updated."
end
