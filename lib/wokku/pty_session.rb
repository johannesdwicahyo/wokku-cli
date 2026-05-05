# frozen_string_literal: true

require "io/console"
require "base64"

module Wokku
  class PtySession
    attr_reader :exit_code

    def initialize(cable:, tty:)
      @cable = cable
      @tty = tty
      @exit_code = nil
      @done = false
    end

    def start!(mode:, target:, argv: [])
      rows, cols = current_winsize
      @cable.send_message(type: "start", mode: mode, target: target, argv: argv, cols: cols, rows: rows)
    end

    # Runs until @done is set by an "exit" or "error" message.
    # Optional block (used in specs) is called once per pump tick and may return :stop.
    def run
      install_message_handler
      install_signal_handlers if @tty

      IO.console.raw! if @tty
      begin
        loop do
          break if @done
          forward_stdin if @tty
          @cable.pump(0.05)
          break if block_given? && yield == :stop
        end
      ensure
        IO.console.cooked! if @tty
      end
    end

    private

    def install_signal_handlers
      Signal.trap("WINCH") do
        rows, cols = current_winsize
        @cable.send_message(type: "resize", cols: cols, rows: rows)
      end
    end

    def install_message_handler
      @cable.on_message do |msg|
        case msg["type"]
        when "stdout"
          $stdout.write(Base64.strict_decode64(msg["data"].to_s))
          $stdout.flush
        when "exit"
          @exit_code = msg["code"].to_i
          @done = true
        when "error"
          warn(msg["message"].to_s)
          @exit_code = 1
          @done = true
        end
      end
    end

    def forward_stdin
      ready = IO.select([$stdin], nil, nil, 0)
      return unless ready
      data = $stdin.read_nonblock(4096)
      @cable.send_message(type: "stdin", data: Base64.strict_encode64(data))
    rescue IO::WaitReadable, EOFError, TypeError
      # nothing to read (TypeError: StringIO in tests, or non-IO stdin)
    end

    def current_winsize
      IO.console.winsize
    rescue
      [24, 80]
    end
  end
end
