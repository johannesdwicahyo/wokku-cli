# frozen_string_literal: true

# --- Releases ---
register "releases", "List releases (usage: wokku releases APP)" do
  id = ARGV.shift || abort("Usage: wokku releases APP")
  data = api(:get, "/apps/#{id}/releases")
  if data.is_a?(Array)
    table(data.map { |r| { "version" => "v#{r['version']}", "description" => r["description"].to_s[0..40], "created" => r["created_at"].to_s[0..18] } })
  else
    puts_json data
  end
end

register "rollback", "Rollback to release (usage: wokku rollback APP RELEASE_ID)" do
  id = ARGV.shift || abort("Usage: wokku rollback APP RELEASE_ID")
  release_id = ARGV.shift || abort("Missing release ID")
  api(:post, "/apps/#{id}/releases/#{release_id}/rollback")
  puts "Rolling back..."
end
