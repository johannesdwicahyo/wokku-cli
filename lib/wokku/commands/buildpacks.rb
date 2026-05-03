# frozen_string_literal: true

# --- Buildpacks ---
register "buildpacks", "List buildpacks (usage: wokku buildpacks APP)" do
  id = ARGV.shift || abort("Usage: wokku buildpacks APP")
  data = api(:get, "/apps/#{id}/buildpacks")
  list = data.is_a?(Hash) ? Array(data["buildpacks"]) : Array(data)
  if list.empty?
    puts "(no buildpacks configured — auto-detected from source)"
  else
    list.each_with_index { |url, i| puts "#{i + 1}. #{url}" }
  end
end

register "buildpacks:add", "Append a buildpack (usage: wokku buildpacks:add APP URL [--index N])" do
  id = ARGV.shift || abort("Usage: wokku buildpacks:add APP URL [--index N]")
  url = ARGV.shift || abort("Missing buildpack URL")
  index = nil
  while arg = ARGV.shift
    index = ARGV.shift if arg == "--index"
  end
  body = { url: url }
  body[:index] = index if index
  api(:post, "/apps/#{id}/buildpacks", body)
  puts "Added buildpack: #{url}"
end

register "buildpacks:remove", "Remove a buildpack (usage: wokku buildpacks:remove APP URL)" do
  id = ARGV.shift || abort("Usage: wokku buildpacks:remove APP URL")
  url = ARGV.shift || abort("Missing buildpack URL")
  api(:delete, "/apps/#{id}/buildpacks", { url: url })
  puts "Removed buildpack: #{url}"
end

register "buildpacks:clear", "Remove every buildpack (usage: wokku buildpacks:clear APP)" do
  id = ARGV.shift || abort("Usage: wokku buildpacks:clear APP")
  api(:delete, "/apps/#{id}/buildpacks")
  puts "All buildpacks removed."
end

register "buildpacks:set", "Replace the buildpack stack in order (usage: wokku buildpacks:set APP URL [URL...])" do
  id = ARGV.shift || abort("Usage: wokku buildpacks:set APP URL [URL...]")
  urls = ARGV.dup
  ARGV.clear
  abort "No buildpack URLs given." if urls.empty?
  api(:put, "/apps/#{id}/buildpacks", { urls: urls })
  puts "Buildpacks set: #{urls.join(', ')}"
end
