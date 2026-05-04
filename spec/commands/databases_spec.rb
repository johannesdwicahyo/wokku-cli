# frozen_string_literal: true

RSpec.describe "databases commands" do
  let(:fake) { FakeApiClient.new }

  describe "databases" do
    it "lists databases as a table" do
      fake.stub(:get, "/databases", returns: [
        { "name" => "mypg", "service_type" => "postgres", "status" => "running", "server_id" => "jkt-01" }
      ])
      result = CliRunner.run("databases", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to include("mypg").and include("postgres").and include("running")
    end

    include_examples "respects --json",
      command: "databases",
      path: "/databases",
      fake_response: [{ "name" => "mypg", "service_type" => "postgres", "status" => "running", "server_id" => "jkt-01" }]
  end

  describe "databases:info" do
    it "GETs /databases/:name and prints JSON" do
      fake.stub(:get, "/databases/mypg", returns: { "name" => "mypg", "service_type" => "postgres", "status" => "running" })
      result = CliRunner.run("databases:info", "mypg", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to include("\"name\": \"mypg\"")
    end

    it "aborts when NAME is missing" do
      result = CliRunner.run("databases:info", api: fake)
      expect(result.exit_code).not_to eq(0)
    end
  end

  describe "databases:create" do
    it "POSTs with name, type, and explicit --server" do
      fake.stub(:post, "/databases", returns: { "name" => "mypg", "service_type" => "postgres" })
      result = CliRunner.run("databases:create", "mypg", "--type", "postgres", "--server", "jkt-01", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to include("Created postgres database: mypg")
      post_call = fake.calls.find { |c| c.method == :post && c.path == "/databases" }
      expect(post_call.body).to eq(name: "mypg", service_type: "postgres", server_id: "jkt-01")
    end

    it "auto-picks the only server when --server omitted" do
      fake.stub(:get, "/servers", returns: [{ "name" => "jkt-01", "host" => "h" }])
      fake.stub(:post, "/databases", returns: { "name" => "mypg", "service_type" => "postgres" })
      result = CliRunner.run("databases:create", "mypg", "--type", "postgres", api: fake)
      expect(result.exit_code).to eq(0)
      post_call = fake.calls.find { |c| c.method == :post && c.path == "/databases" }
      expect(post_call.body).to include(server_id: "jkt-01")
    end

    it "aborts when --type is missing" do
      result = CliRunner.run("databases:create", "mypg", api: fake)
      expect(result.exit_code).not_to eq(0)
      expect(result.stderr + result.stdout).to match(/--type/)
    end

    it "aborts when NAME is missing" do
      result = CliRunner.run("databases:create", api: fake)
      expect(result.exit_code).not_to eq(0)
    end
  end

  describe "databases:destroy" do
    it "DELETEs when confirmed with y" do
      fake.stub(:delete, "/databases/mypg", returns: { "message" => "Database destroyed" })
      result = CliRunner.run("databases:destroy", "mypg", api: fake, stdin: "y\n")
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to include("Database 'mypg' destroyed")
      expect(fake.calls.last.method).to eq(:delete)
    end

    it "cancels when confirmation is not 'y'" do
      result = CliRunner.run("databases:destroy", "mypg", api: fake, stdin: "n\n")
      expect(result.exit_code).not_to eq(0)
      expect(result.stderr + result.stdout).to match(/Cancelled/)
      expect(fake.calls).to be_empty
    end

    it "aborts when NAME is missing" do
      result = CliRunner.run("databases:destroy", api: fake)
      expect(result.exit_code).not_to eq(0)
    end
  end

  describe "databases:link" do
    it "POSTs /databases/:name/link with app_id" do
      fake.stub(:post, "/databases/mypg/link", returns: { "id" => 1 })
      result = CliRunner.run("databases:link", "mypg", "myapp", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to include("Linked 'mypg' to 'myapp'")
      expect(fake.calls.first.body).to eq(app_id: "myapp")
    end

    it "passes alias_name when --alias is given" do
      fake.stub(:post, "/databases/mypg/link", returns: { "id" => 1 })
      result = CliRunner.run("databases:link", "mypg", "myapp", "--alias", "DATABASE", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to include("as DATABASE")
      expect(fake.calls.first.body).to eq(app_id: "myapp", alias_name: "DATABASE")
    end

    it "aborts when APP is missing" do
      result = CliRunner.run("databases:link", "mypg", api: fake)
      expect(result.exit_code).not_to eq(0)
      expect(result.stderr + result.stdout).to match(/Missing APP/)
    end

    it "aborts when DB is missing" do
      result = CliRunner.run("databases:link", api: fake)
      expect(result.exit_code).not_to eq(0)
    end
  end

  describe "databases:unlink" do
    it "POSTs /databases/:name/unlink with app_id" do
      fake.stub(:post, "/databases/mypg/unlink", returns: { "message" => "ok" })
      result = CliRunner.run("databases:unlink", "mypg", "myapp", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to include("Unlinked 'mypg' from 'myapp'")
      expect(fake.calls.first.body).to eq(app_id: "myapp")
    end

    it "aborts when APP is missing" do
      result = CliRunner.run("databases:unlink", "mypg", api: fake)
      expect(result.exit_code).not_to eq(0)
    end
  end
end
