# frozen_string_literal: true

# --- Object storage (one S3-compatible bucket per app) ---
# Named "bucket" so it can't be confused with the old volume `storage` API.
# The S3_* / AWS_* env vars are set on the app automatically.


# The API returns the secret to team members; keep it off the terminal
# (and out of --json) unless asked for with --reveal.
def print_bucket(data, reveal: false)
  data = data.reject { |k, _| k == "secret_access_key" } unless reveal
  Wokku::Output.render(data) do |b|
    puts "Bucket:    #{b['bucket']}"
    puts "Status:    #{b['status']}"
    puts "Used:      #{b['used_gb']} / #{b['quota_gb']} GB"
    puts "Endpoint:  #{b['endpoint']}"
    puts "Region:    #{b['region']}"
    puts "Access:    #{b['access_key_id']}"
    puts "Secret:    #{reveal ? b['secret_access_key'] : '(hidden; add --reveal)'}"
  end
end

register "bucket", "Show an app's object storage bucket (usage: wokku bucket APP [--reveal])" do
  app = ARGV.shift || abort("Usage: wokku bucket APP [--reveal]")
  print_bucket(api(:get, "/apps/#{app}/object_storage"), reveal: ARGV.delete("--reveal"))
end

register "bucket:create", "Enable object storage for an app (usage: wokku bucket:create APP)" do
  app = ARGV.shift || abort("Usage: wokku bucket:create APP")
  data = api(:post, "/apps/#{app}/object_storage")
  Wokku::Output.render(data.reject { |k, _| k == "secret_access_key" }) do |b|
    puts "Bucket #{b['bucket']} is provisioning. The app gets S3_* env vars and restarts when it's ready."
    puts "Check: wokku bucket #{app}"
  end
end

register "bucket:resize", "Change the bucket quota in GB (usage: wokku bucket:resize APP GB)" do
  app = ARGV.shift || abort("Usage: wokku bucket:resize APP GB")
  gb = Integer(ARGV.shift.to_s, exception: false) || abort("Usage: wokku bucket:resize APP GB (a whole number, 1-1024)")
  data = api(:patch, "/apps/#{app}/object_storage", { quota_gb: gb })
  Wokku::Output.status "Quota for #{app}: #{data['quota_gb']} GB"
end

register "bucket:rotate", "Rotate the bucket's access keys; the app restarts onto them (usage: wokku bucket:rotate APP)" do
  app = ARGV.shift || abort("Usage: wokku bucket:rotate APP")
  api(:post, "/apps/#{app}/object_storage/rotate")
  Wokku::Output.status "Rotating keys for #{app}. The old key stops working now; the app restarts with the new one."
end

register "bucket:destroy", "Delete the bucket and all its files (usage: wokku bucket:destroy APP)" do
  app = ARGV.shift || abort("Usage: wokku bucket:destroy APP")
  print "Delete #{app}'s bucket and ALL its files? This cannot be undone. (y/N): "
  abort "Cancelled." unless $stdin.gets.to_s.strip.downcase == "y"
  api(:delete, "/apps/#{app}/object_storage")
  Wokku::Output.status "Deleting #{app}'s bucket."
end
