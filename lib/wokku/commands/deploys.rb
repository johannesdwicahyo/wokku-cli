# frozen_string_literal: true

require "tmpdir"

# --- Deploys ---
register "deploys", "List deploys (usage: wokku deploys APP)" do
  id = ARGV.shift || abort("Usage: wokku deploys APP")
  data = api(:get, "/apps/#{id}/deploys")
  Wokku::Output.render(data) do |d|
    next puts_json(d) unless d.is_a?(Array)
    table(d.map { |x| { "id" => x["id"], "status" => x["status"], "commit" => x["commit_sha"].to_s[0, 7], "created" => x["created_at"].to_s[0..18] } })
  end
end

register "deploys:info", "Show a deploy and its build log (usage: wokku deploys:info APP DEPLOY_ID)" do
  id = ARGV.shift || abort("Usage: wokku deploys:info APP DEPLOY_ID")
  deploy_id = ARGV.shift || abort("Missing DEPLOY_ID")
  data = api(:get, "/apps/#{id}/deploys/#{deploy_id}")
  Wokku::Output.render(data) do |d|
    next puts_json(d) unless d.is_a?(Hash)
    puts "status: #{d['status']}"
    puts d["log"] if d["log"]
  end
end

TERMINAL_DEPLOY_STATUSES = %w[succeeded failed timed_out].freeze

register "deploy:tarball", "Deploy a local directory without git push (usage: wokku deploy:tarball APP [DIR])" do
  id = ARGV.shift || abort("Usage: wokku deploy:tarball APP [DIR]")
  dir = File.expand_path(ARGV.shift || ".")
  abort "Not a directory: #{dir}" unless Dir.exist?(dir)
  if Dir.exist?(File.join(dir, ".git")) && !IO.popen([ "git", "-C", dir, "status", "--porcelain" ], &:read).strip.empty?
    $stderr.puts "warning: uncommitted changes are not deployed (git archive uses HEAD)"
  end
  Dir.mktmpdir do |tmp|
    archive = File.join(tmp, "source.tar.gz")
    build_tarball(dir, archive)
    slot = api(:post, "/apps/#{id}/deploys/uploads")
    upload_presigned(slot["upload_url"], archive)
    dep = api(:post, "/apps/#{id}/deploys", { archive_key: slot["archive_key"] })
    Wokku::Output.status "Build queued (#{dep['deploy_id']}). Following..."
    final = poll_until("/apps/#{id}/deploys/#{dep['deploy_id']}", attempts: 320, interval: 3) { |d| d.is_a?(Hash) && TERMINAL_DEPLOY_STATUSES.include?(d["status"].to_s) }
    abort "Still building after 16 minutes. Check: wokku deploys:info #{id} #{dep['deploy_id']}" unless final
    Wokku::Output.status "Deploy #{final['status']}."
    exit 1 unless final["status"] == "succeeded"
  end
end
