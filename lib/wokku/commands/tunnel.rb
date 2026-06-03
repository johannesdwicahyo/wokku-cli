# frozen_string_literal: true

require "fileutils"
require "open3"
require "rbconfig"
require "tempfile"

# --- wokku tunnel: share a local port at https://<sub>.wokku.dev ---
#
# Path B per project_wokku_tunnel_path_decision (memory): frp gateway.
# Wraps a downloaded `frpc` (one-time bootstrap, no platform-specific
# gem dependency). User runs `wokku tunnel 3000`; we POST to the API
# to provision a TunnelSession, write a per-process frpc.toml, exec
# frpc, and DELETE the session on exit.

FRPC_VERSION = "0.62.1"

def tunnel_frpc_path
  File.join(Dir.home, ".wokku", "bin", "frpc")
end

def tunnel_frpc_platform
  case RbConfig::CONFIG["host_os"]
  when /darwin/  then "darwin_#{tunnel_frpc_arch}"
  when /linux/   then "linux_#{tunnel_frpc_arch}"
  when /mswin|mingw|cygwin/ then "windows_amd64"
  else abort "Unsupported OS: #{RbConfig::CONFIG['host_os']}"
  end
end

def tunnel_frpc_arch
  case RbConfig::CONFIG["host_cpu"]
  when /arm64|aarch64/ then "arm64"
  when /x86_64|amd64/  then "amd64"
  else abort "Unsupported CPU: #{RbConfig::CONFIG['host_cpu']}"
  end
end

def tunnel_ensure_frpc!
  return tunnel_frpc_path if File.executable?(tunnel_frpc_path)

  warn "→ fetching tunnel helper (frpc #{FRPC_VERSION}, ~10 MB, one time)…"
  platform = tunnel_frpc_platform
  archive  = "frp_#{FRPC_VERSION}_#{platform}.tar.gz"
  url      = "https://github.com/fatedier/frp/releases/download/v#{FRPC_VERSION}/#{archive}"
  ext      = platform.start_with?("windows") ? ".zip" : ".tar.gz"
  archive  = archive.sub(/\.tar\.gz\z/, ext)
  url      = url.sub(/\.tar\.gz\z/, ext)

  Dir.mktmpdir do |tmp|
    archive_path = File.join(tmp, archive)
    unless system("curl", "-fL", url, "-o", archive_path)
      abort "Failed to download frpc from #{url}"
    end
    if ext == ".zip"
      system("unzip", "-q", archive_path, "-d", tmp) || abort("unzip failed")
    else
      system("tar", "-C", tmp, "-xzf", archive_path) || abort("tar failed")
    end
    frpc_dir = Dir[File.join(tmp, "frp_#{FRPC_VERSION}_*")].first || abort("frpc not found in archive")
    src = File.join(frpc_dir, platform.start_with?("windows") ? "frpc.exe" : "frpc")
    FileUtils.mkdir_p(File.dirname(tunnel_frpc_path))
    FileUtils.cp(src, tunnel_frpc_path)
    File.chmod(0o755, tunnel_frpc_path)
  end

  tunnel_frpc_path
end

register "tunnel",
         "Share a local port at https://<sub>.wokku.dev. Usage: wokku tunnel PORT [--subdomain S] [--app APP]" do
  args = ARGV.dup
  ARGV.clear

  local_port    = args.shift&.to_i
  abort "Usage: wokku tunnel PORT [--subdomain S] [--app APP]" unless local_port&.positive?

  subdomain = nil
  app_id    = nil
  while (arg = args.shift)
    case arg
    when "--subdomain" then subdomain = args.shift
    when "--app"       then app_id    = args.shift
    end
  end

  payload = {}
  payload[:subdomain]     = subdomain if subdomain
  payload[:app_record_id] = app_id    if app_id

  session = api(:post, "/tunnels", payload)
  if session.is_a?(Hash) && session["error"]
    abort "Failed to create tunnel: #{session['error']}"
  end

  tunnel_id  = session["tunnel_id"]
  token      = session["token"]
  frps_host  = session["frps_host"]
  frps_port  = session["frps_port"]
  public_url = session["public_url"]
  sub        = session["subdomain"]

  warn ""
  warn "  → tunnel: #{public_url} → localhost:#{local_port}"
  warn "  → press Ctrl-C to close"
  warn ""

  frpc = tunnel_ensure_frpc!

  cfg = Tempfile.new([ "frpc-", ".toml" ])
  cfg.write(<<~TOML)
    serverAddr = "#{frps_host}"
    serverPort = #{frps_port}

    [[proxies]]
    name      = "wokku-#{sub}"
    type      = "http"
    localPort = #{local_port}
    subdomain = "#{sub}"

    [proxies.metadatas]
    token = "#{token}"
  TOML
  cfg.close

  cleanup = lambda do
    File.unlink(cfg.path) rescue nil
    api(:delete, "/tunnels/#{tunnel_id}") rescue nil
  end

  %w[INT TERM].each do |sig|
    Signal.trap(sig) do
      cleanup.call
      exit 0
    end
  end

  status = system(frpc, "-c", cfg.path)
  cleanup.call
  exit(status ? 0 : 1)
end
