# frozen_string_literal: true

# --- Process management ---
register "ps:restart", "Restart app (usage: wokku ps:restart APP)" do
  id = ARGV.shift || abort("Usage: wokku ps:restart APP")
  api(:post, "/apps/#{id}/restart")
  puts "Restarting..."
end

register "ps:stop", "Stop app (usage: wokku ps:stop APP)" do
  id = ARGV.shift || abort("Usage: wokku ps:stop APP")
  api(:post, "/apps/#{id}/stop")
  puts "Stopped."
end

register "ps:start", "Start app (usage: wokku ps:start APP)" do
  id = ARGV.shift || abort("Usage: wokku ps:start APP")
  api(:post, "/apps/#{id}/start")
  puts "Started."
end

register "ps:rebuild", "Rebuild + redeploy app (usage: wokku ps:rebuild APP)" do
  id = ARGV.shift || abort("Usage: wokku ps:rebuild APP")
  data = api(:post, "/apps/#{id}/deploy")
  puts "Rebuild triggered. Deploy ##{data['deploy_id']} (release ##{data['release_id']})."
  puts "Tail logs with: wokku logs #{id} --lines 200"
end

register "redeploy", "Redeploy app from latest source (usage: wokku redeploy APP)" do
  id = ARGV.shift || abort("Usage: wokku redeploy APP")
  data = api(:post, "/apps/#{id}/deploy")
  puts "Redeploy triggered. Deploy ##{data['deploy_id']} (release ##{data['release_id']})."
end

register "ps:scale", "Scale processes (usage: wokku ps:scale APP web=2 worker=1)" do
  id = ARGV.shift || abort("Usage: wokku ps:scale APP web=N worker=N")
  scaling = {}
  ARGV.each do |pair|
    type, count = pair.split("=")
    scaling[type] = count.to_i if type && count
  end
  ARGV.clear
  abort "No scaling pairs given. Example: web=2 worker=1" if scaling.empty?
  api(:patch, "/apps/#{id}/ps", { scaling: scaling })
  puts "Scaled: #{scaling.map { |t, c| "#{t}=#{c}" }.join(' ')}"
end
