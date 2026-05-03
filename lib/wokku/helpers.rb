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
