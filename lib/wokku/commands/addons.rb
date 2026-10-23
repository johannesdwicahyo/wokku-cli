# frozen_string_literal: true

# --- Add-ons ---
register "addons", "List add-ons (usage: wokku addons APP)" do
  id = ARGV.shift || abort("Usage: wokku addons APP")
  data = api(:get, "/apps/#{id}/addons")
  Wokku::Output.render(data) do |d|
    if d.is_a?(Array)
      table(d.map { |a|
        {
          "name"   => a["name"],
          "type"   => a["service_type"],
          "kind"   => a["shared"] ? "shared" : "dedicated",
          "status" => a["status"]
        }
      })
    else
      puts_json d
    end
  end
end

register "addons:add", "Retired — use addons:shared:enable or addons:dedicated:upgrade" do
  ARGV.clear
  abort "addons:add is retired — use addons:shared:enable APP ENGINE (free) or addons:dedicated:upgrade APP ENGINE"
end

# --- Bundle v2 — shared engines ---
# User-pick at box creation OR via these commands later. Free plan limited
# to postgres + redis; other plans get all 5 (memcached, rabbitmq, meilisearch
# also available).
register "addons:shared:enable", "Enable a shared engine on an app (usage: wokku addons:shared:enable APP ENGINE). ENGINE: postgres|redis|memcached|rabbitmq|meilisearch" do
  id     = ARGV.shift || abort("Usage: wokku addons:shared:enable APP ENGINE")
  engine = ARGV.shift || abort("Missing engine")
  api(:post, "/apps/#{id}/addons/shared", { engine: engine })

  attempts = (ENV["WOKKU_POLL_ATTEMPTS"] || "30").to_i
  interval = (ENV["WOKKU_POLL_INTERVAL"] || "2").to_f

  Wokku::Output.status "Enabling shared #{engine} on #{id} — provisioning…" unless Wokku.quiet
  final = poll_until("/apps/#{id}/addons", attempts: attempts, interval: interval) do |list|
    row = Array(list).find { |a| a["service_type"] == engine && a["shared"] }
    row && %w[running error].include?(row["status"])
  end

  row = Array(final).find { |a| a["service_type"] == engine && a["shared"] }
  case row && row["status"]
  when "running"
    Wokku::Output.status "Shared #{engine} ready on #{id}."
  when "error"
    abort "Shared #{engine} failed to provision on #{id}. See the dashboard or re-run to retry."
  else
    Wokku::Output.status "Shared #{engine} still provisioning on #{id}. Check: wokku addons #{id}"
  end
end

register "addons:shared:disable", "Disable a shared engine on an app (usage: wokku addons:shared:disable APP ENGINE)" do
  id     = ARGV.shift || abort("Usage: wokku addons:shared:disable APP ENGINE")
  engine = ARGV.shift || abort("Missing engine")
  data   = api(:delete, "/apps/#{id}/addons/shared/#{engine}")
  Wokku::Output.status(data["message"] || "Disabled shared #{engine} on #{id}")
end

# --- Bundle v2 — dedicated upgrade ---
# Pg/Redis migrate from shared (existing data preserved). MySQL/MongoDB
# are fresh-create. Quota: 3 per plan, size follows the box size.
register "addons:dedicated:upgrade", "Upgrade a box to a dedicated DB or Redis (usage: wokku addons:dedicated:upgrade APP ENGINE). ENGINE: postgres|mysql|mongodb|redis" do
  id     = ARGV.shift || abort("Usage: wokku addons:dedicated:upgrade APP ENGINE")
  engine = ARGV.shift || abort("Missing engine (postgres|mysql|mongodb|redis)")
  data   = api(:post, "/apps/#{id}/addons/dedicated", { engine: engine })
  Wokku::Output.status(data["message"] || "Dedicated #{engine} upgrade queued for #{id}")
end

register "addons:remove", "Remove an add-on from an app (usage: wokku addons:remove APP ADDON_ID)" do
  id = ARGV.shift || abort("Usage: wokku addons:remove APP ADDON_ID")
  addon = ARGV.shift || abort("Missing ADDON_ID (see: wokku addons #{id})")
  print "Are you sure you want to remove add-on #{addon} from #{id}? This destroys the database (a farewell snapshot is taken). (y/N): "
  abort "Cancelled." unless $stdin.gets.to_s.strip.downcase == "y"
  api(:delete, "/apps/#{id}/addons/#{addon}")
  Wokku::Output.status "Add-on removed."
end
