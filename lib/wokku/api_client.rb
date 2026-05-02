# frozen_string_literal: true

require "json"
require "net/http"
require "uri"
require_relative "config"

module Wokku
  class ApiClient
    class Error < StandardError; end
    class NotAuthenticated < Error; end
    class Timeout < Error; end
    class Unreachable < Error; end

    OPEN_TIMEOUT = 10
    READ_TIMEOUT = 30

    def initialize(url: nil, token: nil, user_agent: "WokkuCLI")
      @url = url
      @token = token
      @user_agent = user_agent
    end

    def get(path)         = request(:get, path)
    def post(path, body = nil)   = request(:post, path, body)
    def put(path, body = nil)    = request(:put, path, body)
    def patch(path, body = nil)  = request(:patch, path, body)
    def delete(path, body = nil) = request(:delete, path, body)

    def request(method, path, body = nil)
      raise NotAuthenticated, "Not logged in. Run: wokku auth:login" unless token

      uri = URI("#{url}#{path}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = OPEN_TIMEOUT
      http.read_timeout = READ_TIMEOUT

      req = build_request(method, uri)
      req["Authorization"] = "Bearer #{token}"
      req["Content-Type"] = "application/json"
      req["User-Agent"] = @user_agent
      req.body = body.to_json if body

      resp = perform(http, req, uri)
      parse_response(resp)
    end

    private

    def url
      @url || Wokku::Config.api_url
    end

    def token
      @token || Wokku::Config.api_token
    end

    def build_request(method, uri)
      case method
      when :get    then Net::HTTP::Get.new(uri)
      when :post   then Net::HTTP::Post.new(uri)
      when :put    then Net::HTTP::Put.new(uri)
      when :patch  then Net::HTTP::Patch.new(uri)
      when :delete then Net::HTTP::Delete.new(uri)
      else raise ArgumentError, "Unsupported method: #{method}"
      end
    end

    def perform(http, req, uri)
      http.request(req)
    rescue Net::ReadTimeout, Net::OpenTimeout
      raise Timeout, "Request timed out — the server didn't respond in #{READ_TIMEOUT}s."
    rescue SocketError => e
      raise Unreachable, "Cannot reach #{uri.host}: #{e.message.lines.first&.strip}."
    rescue Errno::ECONNREFUSED
      raise Unreachable, "Connection refused by #{uri.host}:#{uri.port}."
    rescue OpenSSL::SSL::SSLError => e
      raise Unreachable, "TLS error talking to #{uri.host}: #{e.message.lines.first&.strip}."
    end

    def parse_response(resp)
      data = JSON.parse(resp.body) rescue resp.body
      return data if resp.is_a?(Net::HTTPSuccess)

      msg = if data.is_a?(Hash)
        data["error"] || data["errors"]&.join(", ") || resp.code
      else
        resp.code
      end
      raise Error, "Error: #{msg}"
    end
  end
end
