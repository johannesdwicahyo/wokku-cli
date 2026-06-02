# frozen_string_literal: true

# --- Scheduled tasks (cron) ---

register "cron", "List scheduled tasks for an app (usage: wokku cron APP)" do
  id = ARGV.shift || abort("Usage: wokku cron APP")
  data = api(:get, "/apps/#{id}/scheduled_tasks")
  tasks = data.is_a?(Array) ? data : []
  if tasks.empty?
    Wokku::Output.status "no scheduled tasks"
    next
  end
  tasks.each do |t|
    Wokku::Output.status "#{t['id']}  #{t['schedule']}  #{t['command']}#{t['description'] ? " (#{t['description']})" : ''}"
  end
end

register "cron:add", "Add a scheduled task. Usage: wokku cron:add APP --schedule '* * * * *' --command 'CMD' [--description 'DESC']" do
  id = ARGV.shift || abort("Usage: wokku cron:add APP --schedule '...' --command '...' [--description '...']")
  schedule = nil
  command  = nil
  description = nil
  while arg = ARGV.shift
    case arg
    when "--schedule"    then schedule    = ARGV.shift
    when "--command"     then command     = ARGV.shift
    when "--description" then description = ARGV.shift
    end
  end
  abort "Missing --schedule" if schedule.nil? || schedule.empty?
  abort "Missing --command"  if command.nil?  || command.empty?

  data = api(:post, "/apps/#{id}/scheduled_tasks", { command: command, schedule: schedule, description: description })
  task_id = data.is_a?(Hash) ? data["id"] : nil
  Wokku::Output.status "Scheduled task added#{task_id ? " (id=#{task_id})" : ''}."
end

register "cron:remove", "Remove a scheduled task (usage: wokku cron:remove APP TASK_ID)" do
  id      = ARGV.shift || abort("Usage: wokku cron:remove APP TASK_ID")
  task_id = ARGV.shift || abort("Missing TASK_ID")
  api(:delete, "/apps/#{id}/scheduled_tasks/#{task_id}")
  Wokku::Output.status "Scheduled task removed."
end
