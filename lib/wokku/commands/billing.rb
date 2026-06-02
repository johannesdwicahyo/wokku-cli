# frozen_string_literal: true

# --- Billing (plan + usage; checkout/portal stay in the dashboard) ---

register "billing:plan", "Show your current Wokku plan + limits (usage: wokku billing:plan)" do
  data = api(:get, "/billing/current_plan")
  data = {} unless data.is_a?(Hash)
  Wokku::Output.status "plan: #{data['plan'] || 'unknown'}"
  Wokku::Output.status "max apps: #{data['max_apps']}"        if data.key?("max_apps")
  Wokku::Output.status "max databases: #{data['max_databases']}" if data.key?("max_databases")
end

register "billing:usage", "Show month-to-date usage (usage: wokku billing:usage)" do
  data = api(:get, "/billing/usage")
  data = {} unless data.is_a?(Hash)

  Wokku::Output.status "current: $#{format('%.2f', data['current_cost_dollars'] || 0.0)}"
  Wokku::Output.status "projected: $#{format('%.2f', data['projected_cost_dollars'] || 0.0)}"
  Wokku::Output.status "payment method: #{data['has_payment_method'] ? 'yes' : 'no'}"

  resources = Array(data["resources"])
  if resources.any?
    Wokku::Output.status ""
    Wokku::Output.status "resources:"
    resources.each do |r|
      cents = r["current_cost_cents"].to_i
      Wokku::Output.status "  #{r['resource_type']}  #{r['tier_name']}  $#{format('%.2f', cents / 100.0)}"
    end
  end
end
