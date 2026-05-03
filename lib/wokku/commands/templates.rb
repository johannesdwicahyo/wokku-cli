# frozen_string_literal: true

# --- Templates ---
register "templates", "List available templates" do
  data = api(:get, "/templates")
  Wokku::Output.render(data) do |d|
    if d.is_a?(Array)
      d.each { |t| puts "#{t['slug'] || t['name']}  #{t['description'].to_s[0..60]}" }
    else
      puts_json d
    end
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
  Wokku::Output.status "Deploying #{slug}..."
  Wokku::Output.render(data) { |d| puts_json d }
end
