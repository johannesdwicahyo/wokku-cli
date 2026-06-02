# frozen_string_literal: true

# --- App lifecycle (rename / clone / lock / unlock / transfer) ---

register "apps:rename", "Rename an app (usage: wokku apps:rename APP NEW_NAME [--force])" do
  id = ARGV.shift || abort("Usage: wokku apps:rename APP NEW_NAME [--force]")
  new_name = ARGV.shift || abort("Missing NEW_NAME. Example: wokku apps:rename myapp myapp-renamed")
  force = ARGV.delete("--force")
  unless force || !$stdout.tty?
    print "Rename `#{id}` to `#{new_name}`? This breaks deployed bookmarks. [y/N] "
    answer = $stdin.gets.to_s.strip.downcase
    abort "Aborted." unless answer == "y"
  end
  data = api(:patch, "/apps/#{id}/rename", { name: new_name })
  Wokku::Output.status "Renamed to #{(data.is_a?(Hash) ? data['name'] : new_name)}."
end

register "apps:clone", "Clone an app config (no env vars/data carried). Usage: wokku apps:clone APP NEW_NAME [--no-skip-deploy]" do
  id = ARGV.shift || abort("Usage: wokku apps:clone APP NEW_NAME [--no-skip-deploy]")
  new_name = ARGV.shift || abort("Missing NEW_NAME. Example: wokku apps:clone myapp myapp-copy")
  skip_deploy = !ARGV.delete("--no-skip-deploy")
  data = api(:post, "/apps/#{id}/clone", { name: new_name, skip_deploy: skip_deploy })
  Wokku::Output.status "Cloned to #{(data.is_a?(Hash) ? data['name'] : new_name)}. Push code to its remote to deploy."
end

register "apps:lock", "Set the dokku deploy lock (blocks future git push). Usage: wokku apps:lock APP" do
  id = ARGV.shift || abort("Usage: wokku apps:lock APP")
  data = api(:post, "/apps/#{id}/lock")
  Wokku::Output.status((data.is_a?(Hash) && data["locked"]) ? "locked" : "ok")
end

register "apps:unlock", "Release the dokku deploy lock. Usage: wokku apps:unlock APP" do
  id = ARGV.shift || abort("Usage: wokku apps:unlock APP")
  data = api(:post, "/apps/#{id}/unlock")
  Wokku::Output.status((data.is_a?(Hash) && data["locked"] == false) ? "unlocked" : "ok")
end

register "apps:transfer", "Initiate an app transfer to another user (they accept via email). Usage: wokku apps:transfer APP RECIPIENT_EMAIL [--force]" do
  id = ARGV.shift || abort("Usage: wokku apps:transfer APP RECIPIENT_EMAIL [--force]")
  recipient = ARGV.shift || abort("Missing RECIPIENT_EMAIL")
  force = ARGV.delete("--force")
  unless force || !$stdout.tty?
    print "Transfer `#{id}` to `#{recipient}`? They must accept via the email link to take ownership. [y/N] "
    answer = $stdin.gets.to_s.strip.downcase
    abort "Aborted." unless answer == "y"
  end
  data = api(:post, "/apps/#{id}/transfer", { recipient_email: recipient })
  email = data.is_a?(Hash) ? data["recipient_email"] : recipient
  Wokku::Output.status "Transfer requested. #{email} will receive an email."
end
