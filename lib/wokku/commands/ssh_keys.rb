# frozen_string_literal: true

# --- SSH keys ---
register "ssh-keys", "List your SSH public keys" do
  data = api(:get, "/ssh_keys")
  Wokku::Output.render(data) do |list|
    table(list.map { |k| {
      "name" => k["name"],
      "fingerprint" => "#{k['fingerprint'].to_s[0..30]}...",
      "created" => k["created_at"].to_s[0..18]
    } })
  end
end

register "ssh-keys:add", "Upload an SSH public key (usage: wokku ssh-keys:add [PATH] --name LABEL)" do
  path = nil
  name = nil
  while arg = ARGV.shift
    case arg
    when "--name" then name = ARGV.shift
    else path ||= arg
    end
  end
  path ||= File.expand_path("~/.ssh/id_ed25519.pub")
  abort "Public key not found at #{path}. Pass an explicit path." unless File.exist?(path)
  abort "Missing --name LABEL" unless name

  public_key = File.read(path).strip
  data = api(:post, "/ssh_keys", { name: name, public_key: public_key })
  Wokku::Output.status "Added SSH key '#{data['name']}' (#{data['fingerprint'][0..20]}...)"
end

register "ssh-keys:remove", "Remove an SSH public key (usage: wokku ssh-keys:remove NAME | --fingerprint SHA — fingerprint takes precedence)" do
  name = nil
  fingerprint = nil
  while arg = ARGV.shift
    case arg
    when "--fingerprint" then fingerprint = ARGV.shift
    else name ||= arg
    end
  end
  abort "Usage: wokku ssh-keys:remove NAME [--fingerprint SHA]" unless name || fingerprint

  list = api(:get, "/ssh_keys")
  match = if fingerprint
    list.find { |k| k["fingerprint"] == fingerprint }
  else
    by_name = list.select { |k| k["name"] == name }
    abort "No SSH key named '#{name}'" if by_name.empty?
    abort "Multiple keys named '#{name}' — pass --fingerprint to disambiguate." if by_name.size > 1
    by_name.first
  end
  abort "SSH key not found" unless match

  api(:delete, "/ssh_keys/#{match['id']}")
  Wokku::Output.status "Removed SSH key '#{match['name']}'"
end
