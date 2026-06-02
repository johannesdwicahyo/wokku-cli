# frozen_string_literal: true

RSpec.describe "apps lifecycle commands" do
  let(:fake) { FakeApiClient.new }

  describe "apps:rename" do
    it "PATCHes /apps/APP/rename with name" do
      fake.stub(:patch, "/apps/myapp/rename", returns: { "id" => "x", "name" => "renamed" })
      result = CliRunner.run("apps:rename", "myapp", "renamed", "--force", api: fake)
      expect(result.exit_code).to eq(0)
      expect(fake.calls.first.body).to eq(name: "renamed")
      expect(result.stdout).to match(/renamed/i)
    end

    it "aborts when args missing" do
      result = CliRunner.run("apps:rename", "myapp", api: fake)
      expect(result.exit_code).not_to eq(0)
    end
  end

  describe "apps:clone" do
    it "POSTs /apps/APP/clone with skip_deploy true by default" do
      fake.stub(:post, "/apps/myapp/clone", returns: { "id" => "n", "name" => "myapp-copy" })
      result = CliRunner.run("apps:clone", "myapp", "myapp-copy", api: fake)
      expect(result.exit_code).to eq(0)
      expect(fake.calls.first.body).to eq(name: "myapp-copy", skip_deploy: true)
      expect(result.stdout).to match(/myapp-copy/)
    end

    it "passes --no-skip-deploy as skip_deploy=false" do
      fake.stub(:post, "/apps/myapp/clone", returns: { "id" => "n", "name" => "myapp-copy" })
      CliRunner.run("apps:clone", "myapp", "myapp-copy", "--no-skip-deploy", api: fake)
      expect(fake.calls.first.body).to eq(name: "myapp-copy", skip_deploy: false)
    end
  end

  describe "apps:lock" do
    it "POSTs /apps/APP/lock" do
      fake.stub(:post, "/apps/myapp/lock", returns: { "locked" => true })
      result = CliRunner.run("apps:lock", "myapp", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to match(/locked/i)
    end
  end

  describe "apps:unlock" do
    it "POSTs /apps/APP/unlock" do
      fake.stub(:post, "/apps/myapp/unlock", returns: { "locked" => false })
      result = CliRunner.run("apps:unlock", "myapp", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to match(/unlocked/i)
    end
  end

  describe "apps:transfer" do
    it "POSTs /apps/APP/transfer with recipient_email" do
      fake.stub(:post, "/apps/myapp/transfer", returns: { "transfer_id" => "t1", "recipient_email" => "to@example.com" })
      result = CliRunner.run("apps:transfer", "myapp", "to@example.com", "--force", api: fake)
      expect(result.exit_code).to eq(0)
      expect(fake.calls.first.body).to eq(recipient_email: "to@example.com")
      expect(result.stdout).to match(/to@example\.com/)
    end
  end
end
