# frozen_string_literal: true

# --- Billing (plan + invoices; paying stays in the dashboard) ---

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

register "billing:invoices", "List your invoices; pay unpaid ones in the dashboard (usage: wokku billing:invoices)" do
  data = api(:get, "/billing/invoices")
  rows = data.is_a?(Array) ? data : []
  if rows.empty?
    Wokku::Output.status "no invoices"
    next
  end
  rows.each do |i|
    line = "#{i['reference']}  #{i['period']}  Rp#{i['amount_idr'].to_i.to_s.reverse.scan(/\d{1,3}/).join('.').reverse}  #{i['status']}"
    line += "  pay: #{i['pay_url']}" if i["pay_url"]
    Wokku::Output.status line
  end
end
