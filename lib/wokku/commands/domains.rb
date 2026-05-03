# frozen_string_literal: true

# --- Domains ---
register "domains", "List domains (usage: wokku domains APP)" do
  id = ARGV.shift || abort("Usage: wokku domains APP")
  data = api(:get, "/apps/#{id}/domains")
  if data.is_a?(Array)
    data.each { |d| puts d["hostname"] || d }
  else
    puts_json data
  end
end

register "domains:add", "Add domain (usage: wokku domains:add APP DOMAIN)" do
  id = ARGV.shift || abort("Usage: wokku domains:add APP DOMAIN")
  domain = ARGV.shift || abort("Missing domain name")
  api(:post, "/apps/#{id}/domains", { hostname: domain })
  puts "Added domain: #{domain}"
end

register "domains:remove", "Remove a domain (usage: wokku domains:remove APP DOMAIN)" do
  id = ARGV.shift || abort("Usage: wokku domains:remove APP DOMAIN")
  domain = ARGV.shift || abort("Missing domain name")
  row = find_domain(id, domain) || abort("No domain '#{domain}' on app #{id}")
  api(:delete, "/apps/#{id}/domains/#{row['id']}")
  puts "Removed domain: #{domain}"
end

register "domains:clear", "Remove every custom domain on an app (usage: wokku domains:clear APP)" do
  id = ARGV.shift || abort("Usage: wokku domains:clear APP")
  list = api(:get, "/apps/#{id}/domains")
  abort "No domains on app #{id}" unless list.is_a?(Array) && list.any?
  list.each do |d|
    api(:delete, "/apps/#{id}/domains/#{d['id']}")
    puts "Removed: #{d['hostname']}"
  end
end
