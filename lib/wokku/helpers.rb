# frozen_string_literal: true

# Cross-command helpers. Defined as top-level methods (matching the
# api/table/puts_json pattern) so command blocks can call them without
# a namespace prefix. Loaded by cli/wokku at boot.

# Look up a domain row by hostname so users can pass the name they know
# rather than an internal id. Returns nil when not found or when the API
# returns a non-array (error envelope).
def find_domain(app_id, hostname)
  list = api(:get, "/apps/#{app_id}/domains")
  return nil unless list.is_a?(Array)
  list.find { |d| d["hostname"] == hostname }
end

# Resolve which server to target for a deploy/create. Walks the
# precedence chain: explicit flag → env → config → auto-pick if
# only one server → abort with helpful error. Returns the server
# name or UUID (whatever was explicitly passed/configured).
def resolve_server(explicit: nil)
  return explicit if explicit
  env = ENV["WOKKU_DEFAULT_SERVER"]
  return env if env && !env.empty?
  cfg_default = Wokku::Config.load["default_server"]
  return cfg_default if cfg_default

  servers = api(:get, "/servers")
  unless servers.is_a?(Array)
    abort "Unexpected response from /servers: #{servers.inspect[0..200]}"
  end
  abort "No servers available. Contact wokku.cloud support." if servers.empty?
  return servers.first["name"] if servers.size == 1

  names = servers.map { |s| s["name"] }.join(", ")
  abort "Multiple servers available (#{names}). Pass --server NAME or set a default: wokku servers:default NAME"
end

# PUT a file to a presigned bucket URL. No Authorization header: the
# signature in the URL is the credential and an extra header breaks it.
def upload_presigned(url, file_path)
  uri = URI(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = uri.scheme == "https"
  http.read_timeout = 300
  req = Net::HTTP::Put.new(uri)
  req["Content-Type"] = "application/gzip"
  req.body = File.binread(file_path)
  resp = http.request(req)
  abort "Upload failed: HTTP #{resp.code}" unless resp.is_a?(Net::HTTPSuccess)
  true
end

# .tar.gz of dir: committed files only for git repos, otherwise everything
# except .git/node_modules/tmp/log. COPYFILE_DISABLE stops macOS tar from
# adding ._ AppleDouble files that break builds.
def build_tarball(dir, archive_path)
  ok = if Dir.exist?(File.join(dir, ".git"))
    system("git", "-C", dir, "archive", "--format=tar.gz", "--output=#{archive_path}", "HEAD")
  else
    system({ "COPYFILE_DISABLE" => "1" }, "tar", "-czf", archive_path,
      "--exclude=.git", "--exclude=node_modules", "--exclude=tmp", "--exclude=log", "-C", dir, ".")
  end
  abort "Could not archive #{dir}" unless ok
end
