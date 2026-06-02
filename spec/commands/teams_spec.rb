# frozen_string_literal: true

RSpec.describe "teams commands" do
  let(:fake) { FakeApiClient.new }

  describe "teams" do
    it "GETs /teams and prints id + name" do
      fake.stub(:get, "/teams", returns: [
        { "id" => "t1", "name" => "Acme" },
        { "id" => "t2", "name" => "Beta" }
      ])
      result = CliRunner.run("teams", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to match(/Acme/)
      expect(result.stdout).to match(/Beta/)
    end

    it "prints a friendly message when no teams" do
      fake.stub(:get, "/teams", returns: [])
      result = CliRunner.run("teams", api: fake)
      expect(result.stdout).to match(/no teams/i)
    end
  end

  describe "teams:create" do
    it "POSTs /teams with name and prints id" do
      fake.stub(:post, "/teams", returns: { "id" => "tnew", "name" => "NewCo" })
      result = CliRunner.run("teams:create", "NewCo", api: fake)
      expect(result.exit_code).to eq(0)
      expect(fake.calls.first.body).to eq(name: "NewCo")
      expect(result.stdout).to match(/tnew/)
    end

    it "aborts when NAME missing" do
      result = CliRunner.run("teams:create", api: fake)
      expect(result.exit_code).not_to eq(0)
    end
  end

  describe "teams:members" do
    it "GETs /teams/TEAM_ID/members and prints rows" do
      fake.stub(:get, "/teams/t1/members", returns: [
        { "id" => "m1", "email" => "a@example.com", "role" => "admin" },
        { "id" => "m2", "email" => "b@example.com", "role" => "member" }
      ])
      result = CliRunner.run("teams:members", "t1", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to match(/a@example\.com/)
      expect(result.stdout).to match(/admin/)
    end

    it "prints a friendly message when no members" do
      fake.stub(:get, "/teams/t1/members", returns: [])
      result = CliRunner.run("teams:members", "t1", api: fake)
      expect(result.stdout).to match(/no members/i)
    end
  end

  describe "teams:members:add" do
    it "POSTs /teams/TEAM_ID/members with email and role=member default" do
      fake.stub(:post, "/teams/t1/members", returns: { "id" => "m3", "email" => "c@example.com", "role" => "member" })
      result = CliRunner.run("teams:members:add", "t1", "--email", "c@example.com", api: fake)
      expect(result.exit_code).to eq(0)
      expect(fake.calls.first.body).to eq(email: "c@example.com", role: "member")
      expect(result.stdout).to match(/m3/)
    end

    it "respects --role admin" do
      fake.stub(:post, "/teams/t1/members", returns: { "id" => "m3" })
      CliRunner.run("teams:members:add", "t1", "--email", "c@example.com", "--role", "admin", api: fake)
      expect(fake.calls.first.body).to eq(email: "c@example.com", role: "admin")
    end

    it "aborts when --email missing" do
      result = CliRunner.run("teams:members:add", "t1", api: fake)
      expect(result.exit_code).not_to eq(0)
    end
  end

  describe "teams:members:remove" do
    it "DELETEs /teams/TEAM_ID/members/MEMBERSHIP_ID" do
      fake.stub(:delete, "/teams/t1/members/m1", returns: nil)
      result = CliRunner.run("teams:members:remove", "t1", "m1", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to match(/removed/i)
    end

    it "aborts when args missing" do
      result = CliRunner.run("teams:members:remove", "t1", api: fake)
      expect(result.exit_code).not_to eq(0)
    end
  end
end
