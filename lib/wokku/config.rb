# frozen_string_literal: true

require "fileutils"
require "json"

module Wokku
  module Config
    DEFAULT_DIR = File.expand_path("~/.wokku")

    module_function

    def dir
      ENV["WOKKU_CONFIG_DIR"] || DEFAULT_DIR
    end

    def file
      File.join(dir, "config.json")
    end

    def load
      return {} unless File.exist?(file)
      JSON.parse(File.read(file))
    rescue StandardError
      {}
    end

    def save(data)
      FileUtils.mkdir_p(dir)
      File.write(file, JSON.pretty_generate(data))
      File.chmod(0600, file)
    end

    def api_url
      load["api_url"] || ENV["WOKKU_API_URL"] || "https://wokku.cloud/api/v1"
    end

    def api_token
      load["token"] || ENV["WOKKU_API_TOKEN"]
    end
  end
end
