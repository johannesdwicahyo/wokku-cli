# frozen_string_literal: true

# --- Teams + team members ---

register "teams", "List the teams you have access to (usage: wokku teams)" do
  data = api(:get, "/teams")
  rows = data.is_a?(Array) ? data : []
  if rows.empty?
    Wokku::Output.status "no teams"
    next
  end
  rows.each do |t|
    Wokku::Output.status "#{t['id']}  #{t['name']}"
  end
end

register "teams:create", "Create a team (usage: wokku teams:create NAME)" do
  name = ARGV.shift || abort("Usage: wokku teams:create NAME")
  data = api(:post, "/teams", { name: name })
  team_id = data.is_a?(Hash) ? data["id"] : nil
  Wokku::Output.status "Team created#{team_id ? " (id=#{team_id})" : ''}."
end

register "teams:members", "List members of a team (usage: wokku teams:members TEAM_ID)" do
  team_id = ARGV.shift || abort("Usage: wokku teams:members TEAM_ID")
  data = api(:get, "/teams/#{team_id}/members")
  rows = data.is_a?(Array) ? data : []
  if rows.empty?
    Wokku::Output.status "no members"
    next
  end
  rows.each do |m|
    Wokku::Output.status "#{m['id']}  #{m['email']}  #{m['role']}"
  end
end

register "teams:members:add", "Add a member to a team. Usage: wokku teams:members:add TEAM_ID --email EMAIL [--role member|admin]" do
  team_id = ARGV.shift || abort("Usage: wokku teams:members:add TEAM_ID --email EMAIL [--role member|admin]")
  email = nil
  role  = "member"
  while arg = ARGV.shift
    case arg
    when "--email" then email = ARGV.shift
    when "--role"  then role  = ARGV.shift
    end
  end
  abort "Missing --email" if email.nil? || email.empty?

  data = api(:post, "/teams/#{team_id}/members", { email: email, role: role })
  membership_id = data.is_a?(Hash) ? data["id"] : nil
  Wokku::Output.status "Added member#{membership_id ? " (id=#{membership_id})" : ''}."
end

register "teams:members:remove", "Remove a member from a team (usage: wokku teams:members:remove TEAM_ID MEMBERSHIP_ID)" do
  team_id = ARGV.shift || abort("Usage: wokku teams:members:remove TEAM_ID MEMBERSHIP_ID")
  membership_id = ARGV.shift || abort("Missing MEMBERSHIP_ID. Get it from `wokku teams:members TEAM_ID`.")
  api(:delete, "/teams/#{team_id}/members/#{membership_id}")
  Wokku::Output.status "Member removed."
end
