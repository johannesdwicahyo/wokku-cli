# frozen_string_literal: true

RSpec.describe "templates and deploy" do
  let(:fake) { FakeApiClient.new }

  describe "templates" do
    it "lists slug + description" do
      fake.stub(:get, "/templates", returns: [{ "slug" => "wp", "description" => "WordPress" }])
      result = CliRunner.run("templates", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to include("wp").and include("WordPress")
    end
  end

  include_examples "respects --json",
    command: "templates",
    path: "/templates",
    fake_response: [{ "slug" => "wp", "description" => "WordPress" }]

  describe "deploy" do
    it "POSTs /templates/deploy with slug + server" do
      fake.stub(:post, "/templates/deploy", returns: { "id" => 1 })
      result = CliRunner.run("deploy", "wp", "--server", "1", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to include("Deploying wp")
      expect(fake.calls.first.body).to eq(slug: "wp", server_id: "1")
    end

    it "passes --name when given" do
      fake.stub(:post, "/templates/deploy", returns: {})
      CliRunner.run("deploy", "wp", "--server", "1", "--name", "myblog", api: fake)
      expect(fake.calls.first.body).to eq(slug: "wp", server_id: "1", name: "myblog")
    end
  end

  describe "deploy server resolution" do
    it "auto-picks the single server when --server omitted" do
      fake.stub(:get, "/servers", returns: [{ "name" => "jkt-01", "host" => "h" }])
      fake.stub(:post, "/templates/deploy", returns: { "id" => 1 })
      result = CliRunner.run("deploy", "wp", api: fake)
      expect(result.exit_code).to eq(0)
      post_call = fake.calls.find { |c| c.method == :post && c.path == "/templates/deploy" }
      expect(post_call.body).to include(slug: "wp", server_id: "jkt-01")
    end

    it "aborts on multi-server with no preference" do
      fake.stub(:get, "/servers", returns: [
        { "name" => "jkt-01", "host" => "h" }, { "name" => "sgp-01", "host" => "h" }
      ])
      result = CliRunner.run("deploy", "wp", api: fake)
      expect(result.exit_code).not_to eq(0)
    end
  end
end
