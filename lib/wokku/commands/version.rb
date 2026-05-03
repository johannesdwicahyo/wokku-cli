# frozen_string_literal: true

register "version", "Show CLI version" do
  Wokku::Output.render({ "version" => VERSION }) { |d| puts "wokku/#{d['version']}" }
end
