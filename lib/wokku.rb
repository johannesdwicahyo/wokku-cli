# frozen_string_literal: true
require "json"
require "net/http"
require "uri"
require "io/console"
require "fileutils"

require "wokku/version"
require "wokku/config"
require "wokku/output"
require "wokku/api_client"
require "wokku/registry"
require "wokku/helpers"
require "wokku/auth"

module Wokku
  class << self
    attr_writer :api_client
    attr_accessor :json, :quiet

    def api_client
      @api_client ||= ApiClient.new(user_agent: "WokkuCLI/#{VERSION}")
    end

    def json?  = !!@json
    def quiet? = !!@quiet
  end

  module CLI
    COMMANDS = Wokku::Registry::COMMANDS

    module_function

    def dispatch(args)
      sep = args.index("--")
      head = sep ? args[0...sep] : args.dup
      tail = sep ? args[sep..] : []
      Wokku.json  = !!head.delete("--json")
      Wokku.quiet = !!(head.delete("--quiet") || head.delete("-q"))
      ARGV.replace(head + tail)
      command = ARGV.shift

      if command.nil? || command == "help" || command == "--help" || command == "-h"
        show_help
        return 0
      elsif COMMANDS[command]
        COMMANDS[command][:handler].call
        return 0
      else
        puts "Unknown command: #{command}"
        puts "Run 'wokku help' for available commands."
        return 1
      end
    end

    def show_help
      puts "Wokku CLI v#{Wokku::VERSION}"
      puts "Usage: wokku COMMAND [args] [--json] [--quiet]"
      puts
      puts "Commands:"
      COMMANDS.sort_by { |k, _| k }.each do |name, cmd|
        puts "  %-20s %s" % [name, cmd[:desc]]
      end
      puts
      puts "Global flags:"
      puts "  --json    Machine-readable JSON output (read commands only)"
      puts "  --quiet   Suppress success messages and hints (alias: -q)"
      puts
      puts "Run 'wokku auth:login' to get started."
    end
  end
end

# Top-level helper shims used by command blocks (preserved for compatibility
# with the existing register-DSL pattern).
def api(method, path, body = nil)
  Wokku.api_client.request(method, path, body)
rescue Wokku::ApiClient::NotAuthenticated, Wokku::ApiClient::Timeout,
       Wokku::ApiClient::Unreachable, Wokku::ApiClient::Error => e
  abort e.message
end

# Poll GET <path> until the block returns truthy (returns that data) or the
# attempt budget is exhausted (returns nil). interval is injectable so specs
# can run with no real sleep.
def poll_until(path, attempts: 30, interval: 2)
  attempts.times do |i|
    data = api(:get, path)
    return data if yield(data)

    sleep(interval) if interval.positive? && i < attempts - 1
  end
  nil
end

def load_config = Wokku::Config.load
def save_config(data) = Wokku::Config.save(data)
def api_url = Wokku::Config.api_url
def api_token = Wokku::Config.api_token
def table(rows, headers: nil) = Wokku::Output.table(rows, headers: headers)
def puts_json(data) = Wokku::Output.puts_json(data)
def register(name, desc, &block) = Wokku::Registry.register(name, desc, &block)

CONFIG_DIR  = Wokku::Config::DEFAULT_DIR
CONFIG_FILE = File.join(CONFIG_DIR, "config.json")
VERSION     = Wokku::VERSION

# Load all command files (they register via the top-level `register` shim).
Dir[File.expand_path("wokku/commands/*.rb", __dir__)].sort.each { |f| require f }
