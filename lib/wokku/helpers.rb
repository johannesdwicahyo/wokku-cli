# frozen_string_literal: true

# Cross-command helpers. Defined as top-level methods (matching the
# api/table/puts_json pattern) so command blocks can call them without
# a namespace prefix. Loaded by cli/wokku at boot.

# Look up a domain row by hostname so users can pass the name they know
# rather than an internal id. Returns nil when not found or when the API
# returns a non-array (error envelope).
def find_domain(app_id, hostname)
  list = api(:get, "/apps/#{app_id}/domains")
  return nil unless list.is_a?(Array)
  list.find { |d| d["hostname"] == hostname }
end

# Resolve which server to target for a deploy/create. Walks the
# precedence chain: explicit flag → env → config → auto-pick if
# only one server → abort with helpful error. Returns the server
# name or UUID (whatever was explicitly passed/configured).
def resolve_server(explicit: nil)
  return explicit if explicit
  env = ENV["WOKKU_DEFAULT_SERVER"]
  return env if env && !env.empty?
  cfg_default = Wokku::Config.load["default_server"]
  return cfg_default if cfg_default

  servers = api(:get, "/servers")
  return servers.first["name"] if servers.is_a?(Array) && servers.size == 1

  names = servers.is_a?(Array) ? servers.map { |s| s["name"] }.join(", ") : "(unknown)"
  abort "Multiple servers available (#{names}). Pass --server NAME or set a default: wokku servers:default NAME"
end
