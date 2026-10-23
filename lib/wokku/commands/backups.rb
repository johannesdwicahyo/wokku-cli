# frozen_string_literal: true

# --- Database backups ---
register "backups", "List backups (usage: wokku backups DB)" do
  db = ARGV.shift || abort("Usage: wokku backups DB")
  data = api(:get, "/databases/#{db}/backups")
  Wokku::Output.render(data) do |d|
    next puts_json(d) unless d.is_a?(Array)
    table(d.map { |b| { "id" => b["id"], "status" => b["status"], "size" => b["size_bytes"], "created" => b["created_at"].to_s[0..18] } })
  end
end

register "backups:capture", "Start a backup now (usage: wokku backups:capture DB)" do
  db = ARGV.shift || abort("Usage: wokku backups:capture DB")
  data = api(:post, "/databases/#{db}/backups")
  Wokku::Output.status "Backup started#{data.is_a?(Hash) && data['id'] ? " (#{data['id']})" : ''}."
end

register "backups:download", "Download a backup, or print its URL (usage: wokku backups:download DB BACKUP_ID [FILE])" do
  db = ARGV.shift || abort("Usage: wokku backups:download DB BACKUP_ID [FILE]")
  backup_id = ARGV.shift || abort("Missing BACKUP_ID")
  out = ARGV.shift
  data = api(:get, "/databases/#{db}/backups/#{backup_id}/download")
  url = data.is_a?(Hash) && data["url"]
  abort "Unexpected response: #{data.inspect[0..200]}" unless url
  next puts(url) unless out

  uri = URI(url)
  Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
    http.request(Net::HTTP::Get.new(uri)) do |resp|
      abort "Download failed: HTTP #{resp.code}" unless resp.is_a?(Net::HTTPSuccess)
      File.open(out, "wb") { |f| resp.read_body { |chunk| f.write(chunk) } }
    end
  end
  Wokku::Output.status "Saved #{out}"
end

register "backups:restore", "Restore a backup — overwrites the database (usage: wokku backups:restore DB BACKUP_ID)" do
  db = ARGV.shift || abort("Usage: wokku backups:restore DB BACKUP_ID")
  backup_id = ARGV.shift || abort("Missing BACKUP_ID")
  print "Are you sure you want to overwrite #{db} with backup #{backup_id}? (y/N): "
  abort "Cancelled." unless $stdin.gets.to_s.strip.downcase == "y"
  data = api(:post, "/databases/#{db}/backups/#{backup_id}/restore")
  Wokku::Output.status((data.is_a?(Hash) && data["message"]) || "Restore requested.")
end
