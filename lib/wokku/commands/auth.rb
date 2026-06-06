# frozen_string_literal: true

# --- Auth ---
register "auth:login", "Authenticate with Wokku via browser device flow" do
  while (arg = ARGV.shift)
    abort "Unknown argument: #{arg}"
  end

  Wokku::Auth.login_with_device_flow!(Wokku::Config.api_url)
end

register "auth:logout", "Log out" do
  path = Wokku::Config.file
  if File.exist?(path)
    File.delete(path)
    Wokku::Output.status "Logged out."
  else
    Wokku::Output.status "Not logged in."
  end
end

register "auth:whoami", "Show current user" do
  data = api(:get, "/auth/whoami")
  Wokku::Output.render(data) do |d|
    puts "Email: #{d['email']}"
    puts "Role:  #{d['role']}"
  end
end
