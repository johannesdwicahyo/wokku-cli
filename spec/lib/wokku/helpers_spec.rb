# frozen_string_literal: true

RSpec.describe "find_domain helper" do
  let(:fake) { FakeApiClient.new }
  before { Wokku.api_client = fake }
  after  { Wokku.api_client = nil }

  it "returns the matching domain row" do
    fake.stub(:get, "/apps/5/domains", returns: [
      { "id" => 1, "hostname" => "a.com" },
      { "id" => 2, "hostname" => "b.com" }
    ])
    expect(find_domain(5, "b.com")).to eq("id" => 2, "hostname" => "b.com")
  end

  it "returns nil when no matching hostname" do
    fake.stub(:get, "/apps/5/domains", returns: [{ "id" => 1, "hostname" => "a.com" }])
    expect(find_domain(5, "missing.com")).to be_nil
  end

  it "returns nil when API returns a non-array" do
    fake.stub(:get, "/apps/5/domains", returns: { "error" => "weird" })
    expect(find_domain(5, "a.com")).to be_nil
  end
end

RSpec.describe "resolve_server helper" do
  let(:fake) { FakeApiClient.new }
  before { Wokku.api_client = fake }
  after  { Wokku.api_client = nil; ENV.delete("WOKKU_DEFAULT_SERVER"); Wokku::Config.save({}) }

  it "returns the explicit value when given" do
    expect(resolve_server(explicit: "jkt-01")).to eq("jkt-01")
  end

  it "returns WOKKU_DEFAULT_SERVER when explicit is nil" do
    ENV["WOKKU_DEFAULT_SERVER"] = "sgp-01"
    expect(resolve_server(explicit: nil)).to eq("sgp-01")
  end

  it "explicit beats env" do
    ENV["WOKKU_DEFAULT_SERVER"] = "sgp-01"
    expect(resolve_server(explicit: "jkt-01")).to eq("jkt-01")
  end

  it "returns config default_server when no explicit and no env" do
    Wokku::Config.save("default_server" => "tkyo-01")
    expect(resolve_server(explicit: nil)).to eq("tkyo-01")
  end

  it "env beats config" do
    Wokku::Config.save("default_server" => "tkyo-01")
    ENV["WOKKU_DEFAULT_SERVER"] = "sgp-01"
    expect(resolve_server(explicit: nil)).to eq("sgp-01")
  end

  it "auto-picks the only server when nothing else is set" do
    fake.stub(:get, "/servers", returns: [{ "name" => "jkt-01", "host" => "h1" }])
    expect(resolve_server(explicit: nil)).to eq("jkt-01")
  end

  it "aborts with helpful message when multiple servers and no preference" do
    fake.stub(:get, "/servers", returns: [
      { "name" => "jkt-01", "host" => "h1" },
      { "name" => "sgp-01", "host" => "h2" }
    ])
    expect { resolve_server(explicit: nil) }.to raise_error(SystemExit)
  end
end
