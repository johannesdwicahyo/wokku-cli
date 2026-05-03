# frozen_string_literal: true

register "version", "Show CLI version" do
  Wokku::Output.render({ "version" => VERSION }) { |_| puts "wokku/#{VERSION}" }
end
