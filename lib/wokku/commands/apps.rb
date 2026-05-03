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

register "apps:create", "Create app (usage: wokku apps:create NAME [--server SERVER] [--branch BRANCH])" do
  name = ARGV.shift || abort("Usage: wokku apps:create NAME [--server SERVER]")
  server = nil
  branch = "main"
  while arg = ARGV.shift
    case arg
    when "--server" then server = ARGV.shift
    when "--branch" then branch = ARGV.shift
    end
  end
  server = resolve_server(explicit: server)
  data = api(:post, "/apps", { name: name, server_id: server, deploy_branch: branch })
  Wokku::Output.status "Created app: #{data['name']} (id: #{data['id']})"
end

register "apps:destroy", "Delete app (usage: wokku apps:destroy APP)" do
  id = ARGV.shift || abort("Usage: wokku apps:destroy APP")
  print "Are you sure you want to delete this app? (y/N): "
  confirm = $stdin.gets.strip
  abort "Cancelled." unless confirm.downcase == "y"
  api(:delete, "/apps/#{id}")
  Wokku::Output.status "App deleted."
end
