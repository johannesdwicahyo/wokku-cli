# frozen_string_literal: true

RSpec.describe FakeApiClient do
  it "returns staged values in sequence, repeating the last" do
    fake = described_class.new
    fake.stub_sequence(:get, "/x", [{ "s" => "a" }, { "s" => "b" }])

    expect(fake.get("/x")).to eq({ "s" => "a" })
    expect(fake.get("/x")).to eq({ "s" => "b" })
    expect(fake.get("/x")).to eq({ "s" => "b" }) # sticks on last
  end
end
