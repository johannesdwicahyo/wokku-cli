# frozen_string_literal: true

DEFAULT_API_URL = "https://wokku.cloud/api/v1"

# --- Auth ---
register "auth:login", "Authenticate with Wokku (device flow; supports Google/GitHub OAuth users). Flags: --url URL, --password (legacy email+password)" do
  url = DEFAULT_API_URL
  use_password = false
  while (arg = ARGV.shift)
    case arg
    when "--url" then url = ARGV.shift or abort "--url requires a value"
    when "--password" then use_password = true
    else abort "Unknown argument: #{arg}"
    end
  end

  if use_password
    Wokku::Auth.login_with_password!(url)
  else
    Wokku::Auth.login_with_device_flow!(url)
  end
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
