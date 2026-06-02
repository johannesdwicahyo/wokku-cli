# frozen_string_literal: true

RSpec.describe "notifications commands" do
  let(:fake) { FakeApiClient.new }

  describe "notifications" do
    it "GETs /notifications and prints" do
      fake.stub(:get, "/notifications", returns: [
        { "id" => "n1", "channel" => "email", "events" => [ "deploy_succeeded" ], "team_id" => "t1" }
      ])
      result = CliRunner.run("notifications", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to match(/email/)
      expect(result.stdout).to match(/deploy_succeeded/)
    end

    it "prints a friendly message on empty list" do
      fake.stub(:get, "/notifications", returns: [])
      result = CliRunner.run("notifications", api: fake)
      expect(result.stdout).to match(/no notifications/i)
    end
  end

  describe "notifications:add" do
    it "POSTs /notifications with team_id, channel=email, and events array" do
      fake.stub(:post, "/notifications", returns: { "id" => "nnew", "channel" => "email" })
      result = CliRunner.run("notifications:add",
                              "--team", "t1",
                              "--channel", "email",
                              "--events", "deploy_succeeded,deploy_failed",
                              api: fake)
      expect(result.exit_code).to eq(0)
      expect(fake.calls.first.body).to eq(
        team_id: "t1",
        channel: "email",
        events: [ "deploy_succeeded", "deploy_failed" ]
      )
      expect(result.stdout).to match(/nnew/)
    end

    it "aborts when --team missing" do
      result = CliRunner.run("notifications:add", "--channel", "email", "--events", "deploy_succeeded", api: fake)
      expect(result.exit_code).not_to eq(0)
    end

    it "aborts when --channel is not email (v1 limit)" do
      result = CliRunner.run("notifications:add",
                              "--team", "t1",
                              "--channel", "slack",
                              "--events", "deploy_succeeded",
                              api: fake)
      expect(result.exit_code).not_to eq(0)
      combined = "#{result.stdout}#{result.stderr}"
      expect(combined).to match(/email/i)
    end

    it "aborts when --events missing" do
      result = CliRunner.run("notifications:add", "--team", "t1", "--channel", "email", api: fake)
      expect(result.exit_code).not_to eq(0)
    end
  end

  describe "notifications:remove" do
    it "DELETEs /notifications/ID" do
      fake.stub(:delete, "/notifications/n1", returns: { "message" => "Notification removed" })
      result = CliRunner.run("notifications:remove", "n1", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to match(/removed/i)
    end

    it "aborts when ID missing" do
      result = CliRunner.run("notifications:remove", api: fake)
      expect(result.exit_code).not_to eq(0)
    end
  end
end
