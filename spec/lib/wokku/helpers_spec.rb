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
