# frozen_string_literal: true

# --- Servers ---
register "servers", "List available servers" do
  data = api(:get, "/servers")
  default_name = Wokku::Config.load["default_server"]
  Wokku::Output.render(data) do |list|
    table(list.map { |s| {
      "name" => s["name"], "host" => s["host"], "status" => s["status"],
      "default" => s["name"] == default_name ? "*" : ""
    } })
  end
end

register "servers:info", "Show server details (usage: wokku servers:info SERVER)" do
  name = ARGV.shift || abort("Usage: wokku servers:info SERVER")
  data = api(:get, "/servers/#{name}")
  Wokku::Output.render(data) { |d| puts_json d }
end

register "servers:default", "Set the default server (usage: wokku servers:default SERVER | --clear)" do
  arg = ARGV.shift || abort("Usage: wokku servers:default SERVER | --clear")
  cfg = Wokku::Config.load
  if arg == "--clear"
    cfg.delete("default_server")
    Wokku::Config.save(cfg)
    Wokku::Output.status "Default server cleared."
  else
    api(:get, "/servers/#{arg}")  # validates server exists; aborts on 404
    cfg["default_server"] = arg
    Wokku::Config.save(cfg)
    Wokku::Output.status "Default server set to: #{arg}"
  end
end
