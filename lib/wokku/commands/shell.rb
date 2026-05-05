# frozen_string_literal: true

require "uri"
require "wokku/cable_client"
require "wokku/pty_session"

# --- wokku enter APP ---
register "enter", "Open an interactive shell in APP's running container (usage: wokku enter APP)" do
  app_name = ARGV.shift or abort "Usage: wokku enter APP"
  Wokku::Commands::Shell.run!(mode: "enter", target_kind: :app, target: app_name, argv: [], force_tty: true)
end

# --- wokku ps:exec APP -- CMD ARGS... ---
register "ps:exec", "Run CMD in a one-off container (like `heroku run`; usage: wokku ps:exec APP [-t|-T] -- CMD [ARGS...])" do
  force = nil
  app_name = nil
  argv = []
  while (arg = ARGV.shift)
    case arg
    when "-t", "--tty"    then force = true
    when "-T", "--no-tty" then force = false
    when "--"             then argv = ARGV.shift(ARGV.length); break
    else app_name ||= arg
    end
  end
  abort "Usage: wokku ps:exec APP [-t|-T] -- CMD [ARGS...]" unless app_name && !argv.empty?
  Wokku::Commands::Shell.run!(mode: "exec", target_kind: :app, target: app_name, argv: argv, force_tty: force)
end

# --- wokku databases:connect DB ---
register "databases:connect", "Open an interactive client for DB (usage: wokku databases:connect DB)" do
  db_name = ARGV.shift or abort "Usage: wokku databases:connect DB"
  Wokku::Commands::Shell.run!(mode: "db_connect", target_kind: :database, target: db_name, argv: [], force_tty: true)
end

module Wokku
  module Commands
    module Shell
      module_function

      def run!(mode:, target_kind:, target:, argv:, force_tty:)
        resource_path = target_kind == :app ? "/apps/#{target}" : "/databases/#{target}"
        resource = api(:get, resource_path)
        server_id = resource["server_id"] or abort "could not resolve server for #{target}"

        token = Wokku::Config.api_token or abort "not logged in — run `wokku auth:login`"
        cable_url = derive_cable_url(Wokku::Config.api_url)

        cable = Wokku::CableClient.new(url: cable_url, token: token)
        cable.subscribe(channel: "TerminalChannel", params: { server_id: server_id })

        tty = force_tty.nil? ? $stdout.tty? : force_tty
        session = Wokku::PtySession.new(cable: cable, tty: tty)
        session.start!(mode: mode, target: target, argv: argv)
        session.run
        cable.close
        exit(session.exit_code || 0)
      end

      def derive_cable_url(api_url)
        u = URI(api_url)
        scheme = u.scheme == "https" ? "wss" : "ws"
        port = (u.port && ![80, 443].include?(u.port)) ? ":#{u.port}" : ""
        "#{scheme}://#{u.host}#{port}/cable"
      end
    end
  end
end
