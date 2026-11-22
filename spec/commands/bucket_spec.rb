# frozen_string_literal: true

RSpec.describe "bucket (object storage) commands" do
  let(:fake) { FakeApiClient.new }
  let(:bucket) do
    { "bucket" => "wk-0123456789ab", "endpoint" => "https://s3.wokku.cloud", "region" => "us-east-1",
      "access_key_id" => "wkabc", "secret_access_key" => "s3cr3t", "quota_gb" => 10, "used_gb" => 1.25,
      "status" => "active", "price_idr_per_gb" => 400, "free_gb" => 1 }
  end

  describe "bucket" do
    it "shows the bucket and hides the secret" do
      fake.stub(:get, "/apps/my-app/object_storage", returns: bucket)
      result = CliRunner.run("bucket", "my-app", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to include("wk-0123456789ab", "https://s3.wokku.cloud", "1.25 / 10 GB", "active", "wkabc")
      expect(result.stdout).not_to include("s3cr3t")
    end

    it "prints the secret with --reveal" do
      fake.stub(:get, "/apps/my-app/object_storage", returns: bucket)
      expect(CliRunner.run("bucket", "my-app", "--reveal", api: fake).stdout).to include("s3cr3t")
    end

    it "keeps the secret out of --json unless --reveal" do
      fake.stub(:get, "/apps/my-app/object_storage", returns: bucket)
      out = CliRunner.run("bucket", "my-app", api: fake, json: true).stdout
      expect(JSON.parse(out)).to include("bucket" => "wk-0123456789ab")
      expect(out).not_to include("s3cr3t")
    end

    it "aborts without APP" do
      expect(CliRunner.run("bucket", api: fake).exit_code).not_to eq(0)
    end
  end

  describe "bucket:create" do
    it "POSTs and says provisioning is queued" do
      fake.stub(:post, "/apps/my-app/object_storage", returns: bucket.merge("status" => "provisioning"))
      result = CliRunner.run("bucket:create", "my-app", api: fake)
      expect(result.exit_code).to eq(0)
      expect(fake.calls.first.method).to eq(:post)
      expect(result.stdout).to include("provisioning")
    end
  end

  describe "bucket:resize" do
    it "PATCHes the quota" do
      fake.stub(:patch, "/apps/my-app/object_storage", returns: bucket.merge("quota_gb" => 20))
      result = CliRunner.run("bucket:resize", "my-app", "20", api: fake)
      expect(result.exit_code).to eq(0)
      expect(fake.calls.first.body).to eq(quota_gb: 20)
      expect(result.stdout).to include("20 GB")
    end

    it "rejects a non-numeric size before calling the API" do
      result = CliRunner.run("bucket:resize", "my-app", "lots", api: fake)
      expect(result.exit_code).not_to eq(0)
      expect(fake.calls).to be_empty
    end
  end

  describe "bucket:rotate" do
    it "POSTs to rotate" do
      fake.stub(:post, "/apps/my-app/object_storage/rotate", returns: bucket)
      expect(CliRunner.run("bucket:rotate", "my-app", api: fake).exit_code).to eq(0)
      expect(fake.calls.first.path).to eq("/apps/my-app/object_storage/rotate")
    end
  end

  describe "bucket:destroy" do
    it "DELETEs after confirmation" do
      fake.stub(:delete, "/apps/my-app/object_storage", returns: bucket.merge("status" => "deleting"))
      result = CliRunner.run("bucket:destroy", "my-app", api: fake, stdin: "y\n")
      expect(result.exit_code).to eq(0)
      expect(fake.calls.first.method).to eq(:delete)
    end

    it "does nothing without confirmation" do
      result = CliRunner.run("bucket:destroy", "my-app", api: fake, stdin: "n\n")
      expect(result.exit_code).not_to eq(0)
      expect(fake.calls).to be_empty
    end
  end
end
