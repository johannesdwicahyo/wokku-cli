# frozen_string_literal: true

# --- Raw dokku passthrough ---
register "do", "Run any dokku command (usage: wokku do APP -- DOKKU_ARGS  |  wokku do --server N -- DOKKU_ARGS)" do
  app    = nil
  server = nil
  force  = false
  while ARGV.any? && ARGV.first != "--"
    arg = ARGV.shift
    case arg
    when "--server"
      server = ARGV.shift
      abort "--server requires a server ID" if server.nil? || server == "--"
    when "--force"  then force = true
    else app ||= arg
    end
  end

  abort "Missing `--` separator. Example: wokku do myapp -- ps:list" unless ARGV.first == "--"
  ARGV.shift  # drop the --
  args = ARGV.dup
  ARGV.clear
  abort "Missing dokku command. Example: wokku do myapp -- ps:list" if args.empty?
  abort "Pass either APP or --server N, not both" if app && server
  abort "Pass APP or --server N before --" if app.nil? && server.nil?

  path = app ? "/apps/#{app}/dokku" : "/servers/#{server}/dokku"
  data = api(:post, path, { args: args, force: force })
  $stdout.write(data["stdout"]) if data["stdout"] && !data["stdout"].empty?
  $stderr.write(data["stderr"]) if data["stderr"] && !data["stderr"].empty?
  exit (data["exit_code"] || 0).to_i
end
