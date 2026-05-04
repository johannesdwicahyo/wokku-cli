# frozen_string_literal: true

# --- Logs ---
register "logs", "View logs (usage: wokku logs APP [--lines N] [--follow|-f])" do
  id = ARGV.shift || abort("Usage: wokku logs APP")
  lines = 100
  follow = false
  while arg = ARGV.shift
    case arg
    when "--lines"        then lines = ARGV.shift.to_i
    when "--follow", "-f" then follow = true
    end
  end

  if follow
    Wokku.api_client.stream(:get, "/apps/#{id}/logs?follow=1") do |chunk|
      $stdout.write(chunk)
      $stdout.flush
    end
  else
    data = api(:get, "/apps/#{id}/logs?lines=#{lines}")
    Wokku::Output.render(data) do |d|
      if d.is_a?(Array)
        d.each { |l| puts l }
      elsif d.is_a?(Hash) && d["logs"]
        puts d["logs"]
      else
        puts_json d
      end
    end
  end
end
