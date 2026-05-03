# frozen_string_literal: true

# --- Activity ---
register "activity", "Show recent activity" do
  data = api(:get, "/activities?limit=20")
  Wokku::Output.render(data) do |d|
    if d.is_a?(Array)
      d.each { |a| puts "#{a['created_at'].to_s[0..18]}  #{a['action']}  #{a['target_name']}" }
    else
      puts_json d
    end
  end
end
