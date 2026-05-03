# frozen_string_literal: true

# --- Add-ons ---
register "addons", "List add-ons (usage: wokku addons APP)" do
  id = ARGV.shift || abort("Usage: wokku addons APP")
  data = api(:get, "/apps/#{id}/addons")
  Wokku::Output.render(data) do |d|
    if d.is_a?(Array)
      table(d.map { |a| { "name" => a["name"], "type" => a["service_type"], "status" => a["status"] } })
    else
      puts_json d
    end
  end
end

register "addons:add", "Add add-on (usage: wokku addons:add APP postgres)" do
  id = ARGV.shift || abort("Usage: wokku addons:add APP SERVICE_TYPE")
  service_type = ARGV.shift || abort("Missing service type (postgres, redis, mysql, etc)")
  name = nil
  while arg = ARGV.shift
    name = ARGV.shift if arg == "--name"
  end
  body = { service_type: service_type }
  body[:name] = name if name
  data = api(:post, "/apps/#{id}/addons", body)
  puts "Added #{service_type}: #{data['name'] || data['id']}"
end
