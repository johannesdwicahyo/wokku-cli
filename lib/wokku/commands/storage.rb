# frozen_string_literal: true

# --- Storage (host-bind volumes) ---
register "storage", "List storage mounts (usage: wokku storage APP)" do
  id = ARGV.shift || abort("Usage: wokku storage APP")
  data = api(:get, "/apps/#{id}/storage")
  list = data.is_a?(Hash) ? Array(data["mounts"]) : Array(data)
  if list.empty?
    puts "(no mounts configured)"
  else
    list.each { |m| puts m }
  end
end

register "storage:mount", "Add a host-bind mount (usage: wokku storage:mount APP HOST_PATH:CONTAINER_PATH)" do
  id = ARGV.shift || abort("Usage: wokku storage:mount APP HOST_PATH:CONTAINER_PATH")
  spec = ARGV.shift || abort("Missing HOST_PATH:CONTAINER_PATH")
  abort "Mount must be HOST_PATH:CONTAINER_PATH" unless spec.include?(":")
  api(:post, "/apps/#{id}/storage", { mount: spec })
  puts "Mounted: #{spec}"
  puts "Restart the app to pick up the mount: wokku ps:restart #{id}"
end

register "storage:unmount", "Remove a host-bind mount (usage: wokku storage:unmount APP HOST_PATH:CONTAINER_PATH)" do
  id = ARGV.shift || abort("Usage: wokku storage:unmount APP HOST_PATH:CONTAINER_PATH")
  spec = ARGV.shift || abort("Missing HOST_PATH:CONTAINER_PATH")
  api(:delete, "/apps/#{id}/storage", { mount: spec })
  puts "Unmounted: #{spec}"
end
