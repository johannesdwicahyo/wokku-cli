# frozen_string_literal: true

# --- API tokens ---
register "tokens", "List API tokens (usage: wokku tokens)" do
  data = api(:get, "/auth/tokens")
  Wokku::Output.render(data) do |d|
    next puts_json(d) unless d.is_a?(Array)
    table(d.map { |t| { "id" => t["id"], "name" => t["name"], "last_used" => t["last_used_at"].to_s[0..18], "expires" => t["expires_at"].to_s[0..18] } })
  end
end

register "tokens:create", "Create an API token (usage: wokku tokens:create NAME)" do
  name = ARGV.shift || abort("Usage: wokku tokens:create NAME")
  data = api(:post, "/auth/tokens", { name: name })
  Wokku::Output.render(data) do |d|
    puts d["token"]
    Wokku::Output.status "Copy it now — it won't be shown again."
  end
end

register "tokens:revoke", "Revoke an API token (usage: wokku tokens:revoke TOKEN_ID)" do
  token_id = ARGV.shift || abort("Usage: wokku tokens:revoke TOKEN_ID")
  api(:delete, "/auth/tokens/#{token_id}")
  Wokku::Output.status "Token revoked."
end
