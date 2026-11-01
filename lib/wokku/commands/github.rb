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

register "github:repos", "List repos the Wokku GitHub App can see, or one repo's branches (usage: wokku github:repos [OWNER/REPO])" do
  repo = ARGV.shift
  if repo
    data = api(:get, "/github/repos?repo=#{URI.encode_www_form_component(repo)}")
    branches = data.is_a?(Hash) ? Array(data["branches"]) : []
    branches.empty? ? Wokku::Output.status("no branches") : branches.each { |b| Wokku::Output.status b }
  else
    rows = api(:get, "/github/repos")
    rows = [] unless rows.is_a?(Array)
    next Wokku::Output.status("no repos — install the Wokku GitHub App on more repositories") if rows.empty?
    rows.each { |r| Wokku::Output.status "#{r['full_name']}  #{r['private'] ? 'private' : 'public'}  #{r['default_branch']}" }
  end
end
