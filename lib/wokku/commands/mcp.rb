# frozen_string_literal: true

# Wokku MCP commands — install / switch / logout the Wokku MCP server
# in Claude Code so the user's CLI token gets passed to the plugin.
# Shells out to `claude mcp` (Claude Code CLI) so we don't need to know
# Claude Code's exact config-file layout — it changes between versions.

MCP_SERVER_NAME = "wokku"

def claude_cli_available?
  system("command -v claude >/dev/null 2>&1")
end

def require_claude_cli!
  return if claude_cli_available?
  abort <<~MSG
    The `claude` CLI is not installed.
    Wokku MCP commands shell out to it to write your Claude Code config.

    Install Claude Code (https://claude.com/claude-code) and retry.
  MSG
end

def require_logged_in!
  return if Wokku::Config.api_token
  abort "Not logged in. Run: wokku auth:login"
end

def install_mcp_entry!
  token = Wokku::Config.api_token

  # Idempotent — silently no-ops if the entry doesn't exist yet.
  system("claude mcp remove #{Shellwords.escape(MCP_SERVER_NAME)} > /dev/null 2>&1")

  # Only the token is passed — the plugin's endpoint is fixed to wokku.cloud.
  ok = system(
    "claude", "mcp", "add", MCP_SERVER_NAME,
    "--env", "WOKKU_API_TOKEN=#{token}",
    "--", "npx", "-y", "@johannesdwicahyo/wokku-plugin"
  )
  ok or abort "claude mcp add failed — check `claude mcp list` and retry."
end

register "mcp:install", "Add the Wokku MCP server to Claude Code with your CLI token" do
  require_claude_cli!
  require_logged_in!
  require "shellwords"

  install_mcp_entry!
  Wokku::Output.status "MCP server '#{MCP_SERVER_NAME}' installed in Claude Code."
  Wokku::Output.status "Restart Claude Code, then ask: \"Deploy this project to Wokku\""
end

register "mcp:switch", "Re-push the current CLI token to the Wokku MCP server (after auth:login)" do
  require_claude_cli!
  require_logged_in!
  require "shellwords"

  install_mcp_entry!
  Wokku::Output.status "MCP server '#{MCP_SERVER_NAME}' now points at the current CLI session."
  Wokku::Output.status "Restart Claude Code for the new token to take effect."
end

register "mcp:logout", "Remove the Wokku MCP server from Claude Code" do
  require_claude_cli!
  require "shellwords"

  ok = system("claude", "mcp", "remove", MCP_SERVER_NAME)
  if ok
    Wokku::Output.status "MCP server '#{MCP_SERVER_NAME}' removed from Claude Code."
  else
    Wokku::Output.status "No MCP entry named '#{MCP_SERVER_NAME}' to remove."
  end
end
