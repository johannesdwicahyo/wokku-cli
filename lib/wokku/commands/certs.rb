# frozen_string_literal: true

# --- TLS / Certs ---
register "certs:enable", "Enable Let's Encrypt SSL on a domain (usage: wokku certs:enable APP DOMAIN)" do
  id = ARGV.shift || abort("Usage: wokku certs:enable APP DOMAIN")
  domain = ARGV.shift || abort("Missing domain name")
  row = find_domain(id, domain) || abort("No domain '#{domain}' on app #{id} — add it first with wokku domains:add")
  api(:post, "/apps/#{id}/domains/#{row['id']}/ssl")
  puts "SSL enabled for #{domain}"
end
