# frozen_string_literal: true

# --- Activity ---
register "activity", "Show recent activity" do
  data = api(:get, "/activities?limit=20")
  if data.is_a?(Array)
    data.each { |a| puts "#{a['created_at'].to_s[0..18]}  #{a['action']}  #{a['target_name']}" }
  else
    puts_json data
  end
end
