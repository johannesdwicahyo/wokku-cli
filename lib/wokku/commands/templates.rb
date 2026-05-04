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

register "deploy", "Deploy template (usage: wokku deploy TEMPLATE [--server SERVER] [--name NAME])" do
  slug = ARGV.shift || abort("Usage: wokku deploy TEMPLATE_SLUG [--server SERVER]")
  server = nil
  name = nil
  while arg = ARGV.shift
    case arg
    when "--server" then server = ARGV.shift
    when "--name" then name = ARGV.shift
    end
  end
  server = resolve_server(explicit: server)
  body = { slug: slug, server_id: server }
  body[:name] = name if name
  data = api(:post, "/templates/deploy", body)
  Wokku::Output.status "Deploying #{slug}..."
  Wokku::Output.render(data) { |d| puts_json d }
end
