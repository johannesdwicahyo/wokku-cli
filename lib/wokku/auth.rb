# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

module Wokku
  # Authentication flows for `wokku auth:login`.
  #
  # CLI requests a device_code + user_code from /auth/device/code, opens
  # the verification URL in the browser, and polls /auth/device/token
  # until the user approves the session in the dashboard. Server returns
  # an api_token which the CLI persists to ~/.wokku/config.
  module Auth
    POLL_FLOOR = 1.0  # don't poll faster than 1s regardless of server hint

    module_function

    def login_with_device_flow!(url)
      code = post_json(url, "/auth/device/code", {})
      user_code  = code.fetch("user_code")
      device_code = code.fetch("device_code")
      verify_uri = code.fetch("verification_uri_complete")
      interval   = (code["interval"] || 5).to_i
      expires_at = Time.now + (code["expires_in"] || 600).to_i

      puts
      puts "  To finish signing in, open this URL in your browser:"
      puts
      puts "    #{verify_uri}"
      puts
      puts "  And confirm the code:  \e[1m#{user_code}\e[0m"
      puts
      open_browser(verify_uri)
      print "  Waiting for approval"

      loop do
        if Time.now > expires_at
          puts
          abort "Login timed out. Run `wokku auth:login` again."
        end

        sleep_for([interval, POLL_FLOOR].max)
        print "."
        $stdout.flush

        resp = post_raw(url, "/auth/device/token", { device_code: device_code })
        body = JSON.parse(resp.body) rescue {}
        case resp.code.to_i
        when 200
          token = body.fetch("token")
          email = body.dig("user", "email")
          save_config({ "token" => token, "email" => email })
          puts
          Wokku::Output.status "Logged in as #{email}"
          Wokku::Output.status "Connected to: #{instance_label(url)}"
          return
        when 202
          # authorization_pending — keep polling
        when 400
          # slow_down — back off
          interval += 5
        when 403
          puts
          abort "Login denied."
        when 410
          puts
          abort "Login code expired. Run `wokku auth:login` again."
        else
          puts
          abort "Login failed: #{resp.code} #{body['error']}"
        end
      end
    end

    def post_json(base_url, path, payload)
      resp = post_raw(base_url, path, payload)
      data = JSON.parse(resp.body) rescue {}
      unless resp.is_a?(Net::HTTPSuccess)
        abort "Request failed: #{resp.code} #{data['error'] || resp.body}"
      end
      data
    end

    def post_raw(base_url, path, payload)
      uri = URI("#{base_url}#{path}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = 10
      http.read_timeout = 30
      req = Net::HTTP::Post.new(uri)
      req["Content-Type"] = "application/json"
      req["Accept"] = "application/json"
      req.body = payload.to_json
      http.request(req)
    end

    def open_browser(url)
      cmd =
        case RUBY_PLATFORM
        when /darwin/  then "open"
        when /mswin|mingw|cygwin/ then "start"
        else "xdg-open"
        end
      # Best-effort; ignore failures (CI, no GUI, etc.)
      system(cmd, url, out: File::NULL, err: File::NULL) rescue nil
    end

    def instance_label(url)
      url.include?("wokku.cloud") ? "wokku.cloud (managed)" : "#{URI(url).host} (self-hosted)"
    end

    def sleep_for(seconds)
      Kernel.sleep(seconds)
    end
  end
end
