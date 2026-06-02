# frozen_string_literal: true

RSpec.describe "cron commands" do
  let(:fake) { FakeApiClient.new }

  describe "cron" do
    it "GETs /apps/APP/scheduled_tasks and prints" do
      fake.stub(:get, "/apps/myapp/scheduled_tasks", returns: [
        { "id" => "t1", "command" => "ls", "schedule" => "*/5 * * * *", "description" => "Tick" }
      ])
      result = CliRunner.run("cron", "myapp", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to match(/t1/)
      expect(result.stdout).to match(/ls/)
    end

    it "prints a friendly message on empty list" do
      fake.stub(:get, "/apps/myapp/scheduled_tasks", returns: [])
      result = CliRunner.run("cron", "myapp", api: fake)
      expect(result.stdout).to match(/no scheduled tasks/i)
    end
  end

  describe "cron:add" do
    it "POSTs with --schedule and --command" do
      fake.stub(:post, "/apps/myapp/scheduled_tasks", returns: { "id" => "tnew", "command" => "x", "schedule" => "*/5 * * * *" })
      result = CliRunner.run("cron:add", "myapp", "--schedule", "*/5 * * * *", "--command", "x", api: fake)
      expect(result.exit_code).to eq(0)
      expect(fake.calls.first.body).to eq(command: "x", schedule: "*/5 * * * *", description: nil)
      expect(result.stdout).to match(/added/i)
    end

    it "passes --description when provided" do
      fake.stub(:post, "/apps/myapp/scheduled_tasks", returns: { "id" => "tnew", "command" => "x", "schedule" => "*/5 * * * *", "description" => "tick" })
      CliRunner.run("cron:add", "myapp", "--schedule", "*/5 * * * *", "--command", "x", "--description", "tick", api: fake)
      expect(fake.calls.first.body).to eq(command: "x", schedule: "*/5 * * * *", description: "tick")
    end

    it "aborts when --schedule or --command missing" do
      result = CliRunner.run("cron:add", "myapp", "--command", "x", api: fake)
      expect(result.exit_code).not_to eq(0)
    end
  end

  describe "cron:remove" do
    it "DELETEs /apps/myapp/scheduled_tasks/ID" do
      fake.stub(:delete, "/apps/myapp/scheduled_tasks/t1", returns: nil)
      result = CliRunner.run("cron:remove", "myapp", "t1", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to match(/removed/i)
    end
  end
end
