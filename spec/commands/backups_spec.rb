# frozen_string_literal: true

require "tmpdir"

RSpec.describe "backups commands" do
  let(:fake) { FakeApiClient.new }

  it "backups lists backups" do
    fake.stub(:get, "/databases/db1/backups", returns: [ { "id" => "b1", "status" => "completed", "size_bytes" => 2048, "created_at" => "2026-10-23T00:00:00Z" } ])
    expect(CliRunner.run("backups", "db1", api: fake).stdout).to include("b1")
  end

  it "backups:capture starts a backup" do
    fake.stub(:post, "/databases/db1/backups", returns: { "id" => "b2", "status" => "pending" })
    expect(CliRunner.run("backups:capture", "db1", api: fake).exit_code).to eq(0)
  end

  it "backups:download prints the URL" do
    fake.stub(:get, "/databases/db1/backups/b1/download", returns: { "url" => "https://bucket.test/b1", "expires_in" => 300 })
    expect(CliRunner.run("backups:download", "db1", "b1", api: fake).stdout).to include("https://bucket.test/b1")
  end

  it "backups:download FILE saves the backup" do
    fake.stub(:get, "/databases/db1/backups/b1/download", returns: { "url" => "https://bucket.test/b1", "expires_in" => 300 })
    stub_request(:get, "https://bucket.test/b1").to_return(status: 200, body: "DUMP")
    Dir.mktmpdir do |dir|
      out = File.join(dir, "b1.dump")
      expect(CliRunner.run("backups:download", "db1", "b1", out, api: fake).exit_code).to eq(0)
      expect(File.read(out)).to eq("DUMP")
    end
  end

  it "backups:restore asks first and restores on y" do
    fake.stub(:post, "/databases/db1/backups/b1/restore", returns: { "message" => "restoring" })
    result = CliRunner.run("backups:restore", "db1", "b1", api: fake, stdin: "y\n")
    expect(result.exit_code).to eq(0)
    expect(result.stdout).to include("restoring")
    expect(fake.calls.last.path).to eq("/databases/db1/backups/b1/restore")
  end

  it "backups:restore cancels on anything but y" do
    result = CliRunner.run("backups:restore", "db1", "b1", api: fake, stdin: "n\n")
    expect(result.exit_code).not_to eq(0)
    expect(fake.calls).to be_empty
  end
end
