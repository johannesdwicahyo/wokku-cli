# frozen_string_literal: true

# --- Process management ---
register "ps:restart", "Restart app (usage: wokku ps:restart APP)" do
  id = ARGV.shift || abort("Usage: wokku ps:restart APP")
  api(:post, "/apps/#{id}/restart")
  Wokku::Output.status "Restarting..."
end

register "ps:stop", "Stop app (usage: wokku ps:stop APP)" do
  id = ARGV.shift || abort("Usage: wokku ps:stop APP")
  api(:post, "/apps/#{id}/stop")
  Wokku::Output.status "Stopped."
end

register "ps:start", "Start app (usage: wokku ps:start APP)" do
  id = ARGV.shift || abort("Usage: wokku ps:start APP")
  api(:post, "/apps/#{id}/start")
  Wokku::Output.status "Started."
end

register "ps:rebuild", "Rebuild + redeploy app (usage: wokku ps:rebuild APP)" do
  id = ARGV.shift || abort("Usage: wokku ps:rebuild APP")
  data = api(:post, "/apps/#{id}/deploy")
  Wokku::Output.status "Rebuild triggered. Deploy ##{data['deploy_id']} (release ##{data['release_id']})."
  Wokku::Output.status "Tail logs with: wokku logs #{id} --lines 200"
end

register "redeploy", "Redeploy app from latest source (usage: wokku redeploy APP)" do
  id = ARGV.shift || abort("Usage: wokku redeploy APP")
  data = api(:post, "/apps/#{id}/deploy")
  Wokku::Output.status "Redeploy triggered. Deploy ##{data['deploy_id']} (release ##{data['release_id']})."
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
  Wokku::Output.status "Scaled: #{scaling.map { |t, c| "#{t}=#{c}" }.join(' ')}"
end

register "ps", "Show process formation (usage: wokku ps APP)" do
  id = ARGV.shift || abort("Usage: wokku ps APP")
  data = api(:get, "/apps/#{id}/ps")
  Wokku::Output.render(data) { |d| d.is_a?(Hash) && d["processes"].is_a?(Hash) ? d["processes"].each { |k, v| puts "#{k}: #{v}" } : puts_json(d) }
end

register "ps:sizes", "List box sizes (usage: wokku ps:sizes)" do
  data = api(:get, "/dyno_tiers")
  Wokku::Output.render(data) { |d| d.is_a?(Array) ? table(d) : puts_json(d) }
end

register "ps:dynos", "Show process allocations and box sizes (usage: wokku ps:dynos APP)" do
  id = ARGV.shift || abort("Usage: wokku ps:dynos APP")
  data = api(:get, "/apps/#{id}/dynos")
  Wokku::Output.render(data) do |d|
    next puts_json(d) unless d.is_a?(Array)
    table(d.map { |a| { "type" => a["process_type"], "count" => a["count"], "size" => a["size_label"], "monthly" => format("%.2f", a["monthly_cost_cents"].to_i / 100.0) } })
  end
end

register "ps:resize", "Change a process type's size (usage: wokku ps:resize APP TYPE --memory MB [--cpu N])" do
  usage = "Usage: wokku ps:resize APP TYPE --memory MB [--cpu N]"
  shape = {}
  if (i = ARGV.index("--memory"))
    shape[:memory_mb] = Integer(ARGV[i + 1] || abort("Missing value for --memory"))
    ARGV.slice!(i, 2)
  end
  if (i = ARGV.index("--cpu"))
    shape[:cpu] = Float(ARGV[i + 1] || abort("Missing value for --cpu"))
    ARGV.slice!(i, 2)
  end
  id = ARGV.shift || abort(usage)
  type = ARGV.shift || abort(usage)
  abort "#{usage} (give --memory and/or --cpu; see: wokku ps:sizes)" if shape.empty?
  api(:patch, "/apps/#{id}/ps", { resources: { type => shape } })
  Wokku::Output.status "Resizing #{type}: #{shape.map { |k, v| "#{k}=#{v}" }.join(' ')}; applied in the background."
end
