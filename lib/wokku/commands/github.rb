# frozen_string_literal: true

# --- GitHub repository connect / disconnect ---

register "github:connect", "Connect a GitHub repo to an app (usage: wokku github:connect APP REPO [--branch BRANCH])" do
  id   = ARGV.shift || abort("Usage: wokku github:connect APP REPO [--branch BRANCH]")
  repo = ARGV.shift || abort("Missing REPO. Example: wokku github:connect myapp owner/repo")
  branch = "main"
  while arg = ARGV.shift
    case arg
    when "--branch" then branch = ARGV.shift || abort("--branch requires a value")
    end
  end

  data = api(:post, "/apps/#{id}/github_connect", { repo: repo, branch: branch })
  message = data.is_a?(Hash) ? data["message"] : nil
  Wokku::Output.status(message || "Connected to #{repo} (#{branch}).")
end

register "github:disconnect", "Disconnect the GitHub repo from an app (usage: wokku github:disconnect APP)" do
  id = ARGV.shift || abort("Usage: wokku github:disconnect APP")
  data = api(:delete, "/apps/#{id}/github_disconnect")
  message = data.is_a?(Hash) ? data["message"] : nil
  Wokku::Output.status(message || "Disconnected.")
end
