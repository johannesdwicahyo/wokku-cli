# frozen_string_literal: true

require "tempfile"

RSpec.describe "ssh-keys commands" do
  let(:fake) { FakeApiClient.new }

  describe "ssh-keys" do
    it "lists keys with name + fingerprint + created" do
      fake.stub(:get, "/ssh_keys", returns: [
        { "name" => "laptop", "fingerprint" => "SHA256:" + ("a" * 43), "created_at" => "2026-05-01T00:00:00Z" }
      ])
      result = CliRunner.run("ssh-keys", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to include("laptop").and include("SHA256:")
    end

    include_examples "respects --json",
      command: "ssh-keys",
      path: "/ssh_keys",
      fake_response: [{ "name" => "laptop", "fingerprint" => "SHA256:abc", "created_at" => "2026-05-01T00:00:00Z" }]
  end

  describe "ssh-keys:add" do
    it "POSTs the public key from the given path" do
      Tempfile.create(["pubkey", ".pub"]) do |f|
        f.write("ssh-ed25519 AAAA... user@host"); f.flush
        fake.stub(:post, "/ssh_keys", returns: { "name" => "laptop", "fingerprint" => "SHA256:abc" })
        result = CliRunner.run("ssh-keys:add", f.path, "--name", "laptop", api: fake)
        expect(result.exit_code).to eq(0)
        expect(result.stdout).to include("Added SSH key 'laptop'")
        expect(fake.calls.first.body).to eq(name: "laptop", public_key: "ssh-ed25519 AAAA... user@host")
      end
    end

    it "defaults path to ~/.ssh/id_ed25519.pub" do
      stub_default = File.expand_path("~/.ssh/id_ed25519.pub")
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(stub_default).and_return(true)
      allow(File).to receive(:read).with(stub_default).and_return("ssh-ed25519 DEFAULT user@host\n")
      fake.stub(:post, "/ssh_keys", returns: { "name" => "default", "fingerprint" => "SHA256:def" })
      result = CliRunner.run("ssh-keys:add", "--name", "default", api: fake)
      expect(result.exit_code).to eq(0)
      expect(fake.calls.first.body).to eq(name: "default", public_key: "ssh-ed25519 DEFAULT user@host")
    end

    it "aborts when --name is missing" do
      Tempfile.create(["pubkey", ".pub"]) do |f|
        f.write("ssh-ed25519 X"); f.flush
        result = CliRunner.run("ssh-keys:add", f.path, api: fake)
        expect(result.exit_code).not_to eq(0)
        expect(result.stderr + result.stdout).to match(/--name/)
      end
    end

    it "aborts when path doesn't exist" do
      result = CliRunner.run("ssh-keys:add", "/nonexistent/path.pub", "--name", "x", api: fake)
      expect(result.exit_code).not_to eq(0)
      expect(result.stderr + result.stdout).to match(/not found/)
    end
  end

  describe "ssh-keys:remove" do
    it "DELETEs by name when unique" do
      fake.stub(:get, "/ssh_keys", returns: [
        { "id" => 1, "name" => "laptop", "fingerprint" => "SHA256:abc" }
      ])
      fake.stub(:delete, "/ssh_keys/1", returns: { "message" => "ok" })
      result = CliRunner.run("ssh-keys:remove", "laptop", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to include("Removed SSH key 'laptop'")
    end

    it "aborts with disambiguation hint when name is ambiguous" do
      fake.stub(:get, "/ssh_keys", returns: [
        { "id" => 1, "name" => "laptop", "fingerprint" => "SHA256:abc" },
        { "id" => 2, "name" => "laptop", "fingerprint" => "SHA256:def" }
      ])
      result = CliRunner.run("ssh-keys:remove", "laptop", api: fake)
      expect(result.exit_code).not_to eq(0)
      expect(result.stderr + result.stdout).to match(/--fingerprint/)
    end

    it "DELETEs by --fingerprint" do
      fake.stub(:get, "/ssh_keys", returns: [
        { "id" => 1, "name" => "laptop", "fingerprint" => "SHA256:abc" },
        { "id" => 2, "name" => "laptop", "fingerprint" => "SHA256:def" }
      ])
      fake.stub(:delete, "/ssh_keys/2", returns: { "message" => "ok" })
      result = CliRunner.run("ssh-keys:remove", "--fingerprint", "SHA256:def", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to include("Removed SSH key 'laptop'")
    end

    it "aborts when no name or fingerprint given" do
      result = CliRunner.run("ssh-keys:remove", api: fake)
      expect(result.exit_code).not_to eq(0)
    end

    it "aborts when name doesn't match any key" do
      fake.stub(:get, "/ssh_keys", returns: [])
      result = CliRunner.run("ssh-keys:remove", "missing", api: fake)
      expect(result.exit_code).not_to eq(0)
      expect(result.stderr + result.stdout).to match(/No SSH key named/)
    end
  end
end
