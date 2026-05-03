# frozen_string_literal: true

# --- Templates ---
register "templates", "List available templates" do
  data = api(:get, "/templates")
  if data.is_a?(Array)
    data.each { |t| puts "#{t['slug'] || t['name']}  #{t['description'].to_s[0..60]}" }
  else
    puts_json data
  end
end

register "deploy", "Deploy template (usage: wokku deploy TEMPLATE --server ID [--name NAME])" do
  slug = ARGV.shift || abort("Usage: wokku deploy TEMPLATE_SLUG --server ID")
  server_id = nil
  name = nil
  while arg = ARGV.shift
    case arg
    when "--server" then server_id = ARGV.shift
    when "--name" then name = ARGV.shift
    end
  end
  abort "Missing --server ID" unless server_id
  body = { slug: slug, server_id: server_id.to_i }
  body[:name] = name if name
  data = api(:post, "/templates/deploy", body)
  puts "Deploying #{slug}..."
  puts_json data
end
