# frozen_string_literal: true

# --- Diagnostics ---
register "doctor", "Check auth, client version, host health and app state (usage: wokku doctor)" do
  data = api(:get, "/doctor")
  Wokku::Output.render(data) { |d| puts_json d }
end

register "ai:diagnose", "AI diagnosis of a failed deploy (usage: wokku ai:diagnose APP [DEPLOY_ID])" do
  id = ARGV.shift || abort("Usage: wokku ai:diagnose APP [DEPLOY_ID]")
  deploy_id = ARGV.shift
  unless deploy_id
    deploys = api(:get, "/apps/#{id}/deploys")
    deploy_id = Array(deploys).first&.dig("id") || abort("No deploys for #{id}")
  end
  data = api(:post, "/ai/diagnose", { deploy_id: deploy_id })
  Wokku::Output.render(data) { |d| d.is_a?(Hash) && d["diagnosis"] ? puts(d["diagnosis"]) : puts_json(d) }
end
