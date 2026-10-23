# frozen_string_literal: true

# --- Billing (plan; checkout/portal stay in the dashboard) ---

register "billing:plan", "Show your current Wokku plan + limits (usage: wokku billing:plan)" do
  data = api(:get, "/billing/current_plan")
  data = {} unless data.is_a?(Hash)
  Wokku::Output.status "plan: #{data['plan'] || 'unknown'}"
  Wokku::Output.status "max apps: #{data['max_apps']}"        if data.key?("max_apps")
  Wokku::Output.status "max databases: #{data['max_databases']}" if data.key?("max_databases")
end

register "billing:usage", "Retired — usage is now per resource (see billing:plan)" do
  abort "billing:usage is retired — usage is now per resource; see wokku billing:plan or the dashboard"
end
