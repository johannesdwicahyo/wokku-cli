# frozen_string_literal: true

# --- Auth ---
register "auth:login", "Authenticate with Wokku" do
  print "Wokku API URL [https://wokku.cloud/api/v1]: "
  url = $stdin.gets.strip
  url = "https://wokku.cloud/api/v1" if url.empty?

  print "Email: "
  email = $stdin.gets.strip
  print "Password: "
  password = ($stdin.respond_to?(:noecho) ? $stdin.noecho(&:gets) : $stdin.gets).strip
  puts

  uri = URI("#{url}/auth/login")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = uri.scheme == "https"
  req = Net::HTTP::Post.new(uri)
  req["Content-Type"] = "application/json"
  req.body = { email: email, password: password }.to_json

  resp = http.request(req)
  data = JSON.parse(resp.body) rescue {}

  if resp.is_a?(Net::HTTPSuccess) && data["token"]
    save_config({ "api_url" => url, "token" => data["token"], "email" => email })
    instance = url.include?("wokku.cloud") ? "wokku.cloud (managed)" : "#{URI(url).host} (self-hosted)"
    puts "Logged in as #{email}"
    puts "Connected to: #{instance}"
  else
    abort "Login failed: #{data['error'] || resp.code}"
  end
end

register "auth:logout", "Log out" do
  path = Wokku::Config.file
  if File.exist?(path)
    File.delete(path)
    puts "Logged out."
  else
    puts "Not logged in."
  end
end

register "auth:whoami", "Show current user" do
  data = api(:get, "/auth/whoami")
  Wokku::Output.render(data) do |d|
    puts "Email: #{d['email']}"
    puts "Role:  #{d['role']}"
  end
end
