# frozen_string_literal: true

# --- Databases ---
register "databases", "List your databases" do
  data = api(:get, "/databases")
  Wokku::Output.render(data) do |list|
    table(Array(list).map { |db| {
      "name" => db["name"],
      "type" => db["service_type"],
      "status" => db["status"],
      "server" => db["server_id"]
    } })
  end
end

register "databases:info", "Show database details (usage: wokku databases:info NAME)" do
  name = ARGV.shift || abort("Usage: wokku databases:info NAME")
  data = api(:get, "/databases/#{name}")
  Wokku::Output.render(data) { |d| puts_json d }
end

register "databases:create", "Create a database (usage: wokku databases:create NAME --type TYPE [--server SERVER])" do
  name = ARGV.shift || abort("Usage: wokku databases:create NAME --type TYPE [--server SERVER]")
  type = nil
  server = nil
  while arg = ARGV.shift
    case arg
    when "--type"   then type = ARGV.shift
    when "--server" then server = ARGV.shift
    end
  end
  abort "Missing --type (postgres, mysql, redis, mongo)" unless type
  server = resolve_server(explicit: server)
  data = api(:post, "/databases", { name: name, service_type: type, server_id: server })
  Wokku::Output.status "Created #{data['service_type']} database: #{data['name']}"
end

register "databases:destroy", "Destroy a database (usage: wokku databases:destroy NAME)" do
  name = ARGV.shift || abort("Usage: wokku databases:destroy NAME")
  print "Are you sure you want to destroy database '#{name}'? (y/N): "
  confirm = $stdin.gets.to_s.strip
  abort "Cancelled." unless confirm.downcase == "y"
  api(:delete, "/databases/#{name}")
  Wokku::Output.status "Database '#{name}' destroyed."
end

register "databases:link", "Link a database to an app (usage: wokku databases:link DB APP [--alias ALIAS])" do
  db_name = ARGV.shift || abort("Usage: wokku databases:link DB APP [--alias ALIAS]")
  app = ARGV.shift || abort("Missing APP")
  alias_name = nil
  while arg = ARGV.shift
    case arg
    when "--alias" then alias_name = ARGV.shift
    end
  end
  body = { app_id: app }
  body[:alias_name] = alias_name if alias_name
  api(:post, "/databases/#{db_name}/link", body)
  Wokku::Output.status "Linked '#{db_name}' to '#{app}'#{alias_name ? " as #{alias_name}" : ""}."
end

register "databases:unlink", "Unlink a database from an app (usage: wokku databases:unlink DB APP)" do
  db_name = ARGV.shift || abort("Usage: wokku databases:unlink DB APP")
  app = ARGV.shift || abort("Missing APP")
  api(:post, "/databases/#{db_name}/unlink", { app_id: app })
  Wokku::Output.status "Unlinked '#{db_name}' from '#{app}'."
end
