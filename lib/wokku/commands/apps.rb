# frozen_string_literal: true

# --- Apps ---
register "apps", "List all apps" do
  apps = api(:get, "/apps")
  Wokku::Output.render(apps) do |list|
    table(list.map { |a| { "name" => a["name"], "status" => a["status"], "server" => a["server_id"] } })
  end
end

register "apps:info", "Show app details (usage: wokku apps:info APP)" do
  id = ARGV.shift || abort("Usage: wokku apps:info APP")
  data = api(:get, "/apps/#{id}")
  Wokku::Output.render(data) { |d| puts_json d }
end

register "apps:create", "Create app (usage: wokku apps:create NAME [--server SERVER] [--branch BRANCH] [--box-size SIZE] [--shared pg,redis,...] [--dedicated-db postgres|mysql|mongodb] [--dedicated-redis])" do
  name = ARGV.shift || abort("Usage: wokku apps:create NAME [--server SERVER]")
  server = nil
  branch = "main"
  box_size = nil
  shared = nil
  dedicated_db = nil
  dedicated_redis = false
  while (arg = ARGV.shift)
    case arg
    when "--server"           then server = ARGV.shift
    when "--branch"           then branch = ARGV.shift
    when "--box-size"         then box_size = ARGV.shift
    when "--shared"           then shared = ARGV.shift  # comma-separated engine names
    when "--dedicated-db"     then dedicated_db = ARGV.shift
    when "--dedicated-redis"  then dedicated_redis = true
    end
  end
  server = resolve_server(explicit: server)
  body = { name: name, server_id: server, deploy_branch: branch }
  body[:box_size] = box_size if box_size
  body[:enabled_shared_engines] = shared.split(",").map(&:strip) if shared
  body[:dedicated_db_engine] = dedicated_db if dedicated_db
  body[:add_dedicated_redis] = true if dedicated_redis
  data = api(:post, "/apps", body)
  Wokku::Output.status "Created app: #{data['name']} (id: #{data['id']})"
  Array(data["warnings"]).each { |w| Wokku::Output.warn(w) }
end

register "apps:destroy", "Delete app (usage: wokku apps:destroy APP)" do
  id = ARGV.shift || abort("Usage: wokku apps:destroy APP")
  print "Are you sure you want to delete this app? (y/N): "
  confirm = $stdin.gets.strip
  abort "Cancelled." unless confirm.downcase == "y"
  api(:delete, "/apps/#{id}")
  Wokku::Output.status "App deleted."
end
