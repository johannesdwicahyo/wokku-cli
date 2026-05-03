# frozen_string_literal: true

# --- Config ---
register "config", "Show config vars (usage: wokku config APP)" do
  id = ARGV.shift || abort("Usage: wokku config APP")
  data = api(:get, "/apps/#{id}/config")
  Wokku::Output.render(data) do |d|
    if d.is_a?(Hash)
      d.each { |k, v| puts "#{k}=#{v}" }
    else
      puts_json d
    end
  end
end

register "config:set", "Set config vars (usage: wokku config:set APP KEY=VAL ...)" do
  id = ARGV.shift || abort("Usage: wokku config:set APP KEY=VALUE ...")
  vars = {}
  ARGV.each do |pair|
    key, val = pair.split("=", 2)
    vars[key] = val if key && val
  end
  ARGV.clear
  abort "No KEY=VALUE pairs given." if vars.empty?
  # Server expects { vars: { K: V } }, not the bare hash. Sending the bare
  # hash worked previously because Rails was permissive; the controller
  # actually reads params[:vars].
  api(:put, "/apps/#{id}/config", { vars: vars })
  puts "Config updated: #{vars.keys.join(', ')}"
  puts "Restart the app to pick up changes: wokku ps:restart #{id}"
end

register "config:get", "Show one config var (usage: wokku config:get APP KEY)" do
  id = ARGV.shift || abort("Usage: wokku config:get APP KEY")
  key = ARGV.shift || abort("Missing KEY")
  data = api(:get, "/apps/#{id}/config")
  vars = data.is_a?(Hash) ? (data["config"] || data) : {}
  abort "Key not set: #{key}" unless vars.key?(key)
  Wokku::Output.render(vars[key]) { |v| puts v }
end

register "config:unset", "Remove config vars (usage: wokku config:unset APP KEY [KEY...])" do
  id = ARGV.shift || abort("Usage: wokku config:unset APP KEY [KEY...]")
  keys = ARGV.dup
  ARGV.clear
  abort "No KEYs given." if keys.empty?
  api(:delete, "/apps/#{id}/config", { keys: keys })
  puts "Removed: #{keys.join(', ')}"
  puts "Restart the app to pick up changes: wokku ps:restart #{id}"
end
