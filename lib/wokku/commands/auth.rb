# frozen_string_literal: true

# --- Auth ---
register "auth:login", "Authenticate with Wokku via browser device flow" do
  while (arg = ARGV.shift)
    abort "Unknown argument: #{arg}"
  end

  Wokku::Auth.login_with_device_flow!(Wokku::Config.api_url)
end

register "auth:logout", "Log out (revokes this token on the server)" do
  path = Wokku::Config.file
  if File.exist?(path)
    begin
      # covers: api(:delete, "/auth/logout")
      # only revoke a token this file holds, never an env-provided (CI) one
      Wokku.api_client.request(:delete, "/auth/logout") if Wokku::Config.load["token"]
    rescue Wokku::ApiClient::NotAuthenticated, Wokku::ApiClient::Timeout,
           Wokku::ApiClient::Unreachable, Wokku::ApiClient::Error
      nil # best effort: always clear the local login
    end
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
