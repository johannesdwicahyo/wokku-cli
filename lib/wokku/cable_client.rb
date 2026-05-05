# frozen_string_literal: true

require "json"
require "socket"
require "openssl"
require "uri"
require "websocket/driver"

module Wokku
  class CableClient
    SUBSCRIBE_TIMEOUT = 10

    def initialize(url:, token:)
      @uri = URI(url)
      @token = token
      @on_message = ->(_) {}
      @on_close = ->(_) {}
      @subscribed = false
      @identifier = nil
      @socket = open_socket
      @driver = WebSocket::Driver.client(self)
      @driver.set_header("Authorization", "Bearer #{@token}") if @token && !@token.empty?
      attach_driver_callbacks
      @driver.start
    end

    # WebSocket::Driver duck-types these on its socket adapter:
    def url
      @uri.to_s
    end

    def write(data)
      @socket.write(data)
    end

    def on_message(&block)
      @on_message = block
    end

    def on_close(&block)
      @on_close = block
    end

    def subscribe(channel:, params: {})
      @identifier = JSON.dump({ channel: channel, **params })
      @driver.text(JSON.dump(command: "subscribe", identifier: @identifier))
      deadline = Time.now + SUBSCRIBE_TIMEOUT
      pump_until { @subscribed || Time.now > deadline }
      raise "subscribe timed out" unless @subscribed
    end

    def send_message(payload)
      @driver.text(JSON.dump(command: "message", identifier: @identifier, data: JSON.dump(payload)))
    end

    def pump(timeout = 0.05)
      ready = IO.select([@socket], nil, nil, timeout)
      return unless ready
      @driver.parse(@socket.read_nonblock(4096))
    rescue IO::WaitReadable
      # transient
    rescue EOFError
      @on_close.call(:eof)
    end

    def close
      @driver.close rescue nil
      @socket.close rescue nil
    end

    private

    def open_socket
      tcp = TCPSocket.new(@uri.host, @uri.port || (@uri.scheme == "wss" ? 443 : 80))
      return tcp if @uri.scheme == "ws"

      ctx = OpenSSL::SSL::SSLContext.new
      ctx.set_params
      ssl = OpenSSL::SSL::SSLSocket.new(tcp, ctx)
      ssl.hostname = @uri.host
      ssl.sync_close = true
      ssl.connect
      ssl
    end

    def attach_driver_callbacks
      @driver.on(:message) { |e| dispatch_frame(e.data) }
      @driver.on(:close)   { |e| @on_close.call(e) }
      @driver.on(:error)   { |e| @on_close.call(e) }
    end

    def dispatch_frame(text)
      frame = JSON.parse(text)
      case frame["type"]
      when "confirm_subscription"
        @subscribed = true
      when "ping", "welcome"
        # ignore
      else
        msg = frame["message"]
        @on_message.call(msg) if msg
      end
    end

    def pump_until
      until yield
        pump(0.05)
      end
    end
  end
end
