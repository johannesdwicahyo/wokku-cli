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

register "addons:add", "[LEGACY pre-Bundle-v2] Add add-on (usage: wokku addons:add APP postgres). Returns 410 under Bundle v2 — use addons:shared:enable or addons:dedicated:upgrade instead." do
  id = ARGV.shift || abort("Usage: wokku addons:add APP SERVICE_TYPE")
  service_type = ARGV.shift || abort("Missing service type (postgres, redis, mysql, etc)")
  name = nil
  while (arg = ARGV.shift)
    name = ARGV.shift if arg == "--name"
  end
  body = { service_type: service_type }
  body[:name] = name if name
  data = api(:post, "/apps/#{id}/addons", body)
  Wokku::Output.status "Added #{service_type}: #{data['name'] || data['id']}"
end

# --- Bundle v2 — shared engines ---
# User-pick at box creation OR via these commands later. Free plan limited
# to postgres + redis; other plans get all 5 (memcached, rabbitmq, meilisearch
# also available).
register "addons:shared:enable", "Enable a shared engine on an app (usage: wokku addons:shared:enable APP ENGINE). ENGINE: postgres|redis|memcached|rabbitmq|meilisearch" do
  id     = ARGV.shift || abort("Usage: wokku addons:shared:enable APP ENGINE")
  engine = ARGV.shift || abort("Missing engine")
  data   = api(:post, "/apps/#{id}/addons/shared", { engine: engine })
  Wokku::Output.status(data["message"] || "Enabled shared #{engine} on #{id}")
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
