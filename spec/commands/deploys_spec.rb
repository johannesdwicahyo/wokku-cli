# frozen_string_literal: true

RSpec.describe "deploys commands" do
  let(:fake) { FakeApiClient.new }

  include_examples "passes APP through verbatim", command: "deploys", path_pattern: "/apps/APP/deploys", api_method: :get

  it "deploys lists deploys" do
    fake.stub(:get, "/apps/a/deploys", returns: [ { "id" => "d1", "status" => "succeeded", "commit_sha" => "abc1234", "created_at" => "2026-10-23T01:02:03Z" } ])
    expect(CliRunner.run("deploys", "a", api: fake).stdout).to include("succeeded")
  end

  it "deploys:info shows one deploy" do
    fake.stub(:get, "/apps/a/deploys/d1", returns: { "id" => "d1", "status" => "failed", "log" => "line1\nERROR here" })
    expect(CliRunner.run("deploys:info", "a", "d1", api: fake).stdout).to include("ERROR here")
  end

  describe "deploy:tarball" do
    it "uploads the archive, creates the deploy and follows it to success" do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, "index.html"), "hi")
        fake.stub(:post, "/apps/a/deploys/uploads", returns: { "archive_key" => "k1", "upload_url" => "https://bucket.test/k1", "expires_in" => 900 })
        fake.stub(:post, "/apps/a/deploys", returns: { "deploy_id" => "d9", "status" => "queued" })
        fake.stub(:get, "/apps/a/deploys/d9", returns: { "id" => "d9", "status" => "succeeded" })
        stub_request(:put, "https://bucket.test/k1").to_return(status: 200)
        result = CliRunner.run("deploy:tarball", "a", dir, api: fake)
        expect(result.exit_code).to eq(0)
        expect(fake.calls.map { |c| [ c.method, c.path ] }).to include([ :post, "/apps/a/deploys" ])
        expect(fake.calls.find { |c| c.path == "/apps/a/deploys" }.body).to eq(archive_key: "k1")
      end
    end

    it "exits 1 when the deploy fails" do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, "index.html"), "hi")
        fake.stub(:post, "/apps/a/deploys/uploads", returns: { "archive_key" => "k1", "upload_url" => "https://bucket.test/k1" })
        fake.stub(:post, "/apps/a/deploys", returns: { "deploy_id" => "d9" })
        fake.stub(:get, "/apps/a/deploys/d9", returns: { "status" => "failed" })
        stub_request(:put, "https://bucket.test/k1").to_return(status: 200)
        expect(CliRunner.run("deploy:tarball", "a", dir, api: fake).exit_code).to eq(1)
      end
    end
  end
end
