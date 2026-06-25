# frozen_string_literal: true

RSpec.describe "poll_until helper" do
  let(:fake) { FakeApiClient.new }

  before { Wokku.api_client = fake }
  after  { Wokku.api_client = nil }

  it "returns the first data for which the block is truthy" do
    fake.stub_sequence(:get, "/r", [{ "status" => "creating" }, { "status" => "running" }])
    result = poll_until("/r", attempts: 5, interval: 0) { |d| d["status"] == "running" }
    expect(result).to eq({ "status" => "running" })
  end

  it "returns nil when attempts are exhausted without a match" do
    fake.stub(:get, "/r", returns: { "status" => "creating" })
    result = poll_until("/r", attempts: 3, interval: 0) { |d| d["status"] == "running" }
    expect(result).to be_nil
  end
end
