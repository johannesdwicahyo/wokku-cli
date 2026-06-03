# frozen_string_literal: true

require "socket"
require "uri"

# --- wokku dev: prod env + read-only DB tunnel for local dev ---

register "dev",
         "Run a local command with prod env + read-only DB tunnel. Usage: wokku dev APP [--duration MIN] [--rw] [--local-port N] -- CMD [ARGS...]" do
  args = ARGV.dup
  ARGV.clear

  id        = args.shift || abort("Usage: wokku dev APP [flags] -- CMD [ARGS...]")
  duration  = 30
  readwrite = false
  local_port = 5433
  user_cmd  = nil

  while (arg = args.shift)
    case arg
    when "--duration"   then duration = args.shift.to_i
    when "--rw"         then readwrite = true
    when "--local-port" then local_port = args.shift.to_i
    when "--"           then user_cmd = args.dup; break
    end
  end

  abort "Missing user command. Add `-- bin/rails s` (or similar) after wokku flags." if user_cmd.nil? || user_cmd.empty?

  session = api(:post, "/apps/#{id}/dev_sessions", { duration_min: duration.positive? ? duration : 30 })
  session_id = session["session_id"]

  tunnel_args = [
    "ssh", "-N",
    "-L", "#{local_port}:#{session['db_remote_host']}:#{session['db_remote_port']}",
    "-p", session["ssh_port"].to_s,
    "-o", "ExitOnForwardFailure=yes",
    "-o", "ServerAliveInterval=30",
    "-o", "StrictHostKeyChecking=accept-new",
    "#{session['ssh_user']}@#{session['ssh_host']}"
  ]
  tunnel_pid = Process.spawn(*tunnel_args)

  ready = false
  10.times do
    begin
      Socket.tcp("127.0.0.1", local_port, connect_timeout: 0.5) { |s| s.close rescue nil }
      ready = true
    rescue StandardError
      sleep 0.5
    end
    break if ready
  end

  unless ready
    Process.kill("TERM", tunnel_pid) rescue nil
    api(:delete, "/apps/#{id}/dev_sessions/#{session_id}") rescue nil
    abort "SSH tunnel failed to come up on port #{local_port}. Aborting."
  end

  env_data = api(:get, "/apps/#{id}/config")
  env = env_data.is_a?(Hash) ? env_data.dup : {}

  if env["DATABASE_URL"].to_s.start_with?("postgres")
    db = URI.parse(env["DATABASE_URL"])
    db.host = "localhost"
    db.port = local_port

    if readwrite
      warn "⚠️  --rw MODE: writes will hit PROD database. 5s to Ctrl-C..."
      sleep 5 unless ENV["WOKKU_DEV_SKIP_SLEEP"] == "1"
    else
      existing_query = db.query.to_s
      ro = "options=-c%20default_transaction_read_only%3Don"
      db.query = existing_query.empty? ? ro : "#{existing_query}&#{ro}"
    end

    env["DATABASE_URL"] = db.to_s
  end

  exit_status = nil
  begin
    user_pid = Process.spawn(env, *user_cmd)
    _, status = Process.wait2(user_pid)
    exit_status = status.exitstatus || 0
  ensure
    Process.kill("TERM", tunnel_pid) rescue nil
    api(:delete, "/apps/#{id}/dev_sessions/#{session_id}") rescue nil
  end

  exit exit_status if exit_status
end
