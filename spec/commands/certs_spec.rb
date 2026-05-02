# frozen_string_literal: true

RSpec.describe "certs commands" do
  let(:fake) { FakeApiClient.new }

  describe "certs:enable" do
    it "POSTs /apps/:id/domains/:dom/ssl after looking up the domain" do
      fake.stub(:get, "/apps/5/domains", returns: [{ "id" => 9, "hostname" => "x.com" }])
      fake.stub(:post, "/apps/5/domains/9/ssl", returns: {})
      result = CliRunner.run("certs:enable", "5", "x.com", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to include("SSL enabled for x.com")
    end

    it "aborts when domain not found" do
      fake.stub(:get, "/apps/5/domains", returns: [])
      result = CliRunner.run("certs:enable", "5", "missing.com", api: fake)
      expect(result.exit_code).not_to eq(0)
    end
  end
end
