# frozen_string_literal: true

RSpec.describe "vitals command" do
  let(:fake) { FakeApiClient.new }

  it "GETs /apps/APP/vitals and prints p75 per metric" do
    fake.stub(:get, "/apps/myapp/vitals", returns: {
      "latest" => {
        "LCP" => { "p75" => 200, "sample_count" => 5 },
        "CLS" => { "p75" => 0.05, "sample_count" => 3 },
        "INP" => nil, "FCP" => nil, "TTFB" => nil
      }
    })
    result = CliRunner.run("vitals", "myapp", api: fake)
    expect(result.exit_code).to eq(0)
    expect(result.stdout).to match(/LCP: 200/)
    expect(result.stdout).to match(/CLS: 0\.05/)
    expect(result.stdout).to match(/INP: —/)
  end

  it "prints a friendly message when latest is fully empty" do
    fake.stub(:get, "/apps/myapp/vitals", returns: {
      "latest" => { "LCP" => nil, "CLS" => nil, "INP" => nil, "FCP" => nil, "TTFB" => nil }
    })
    result = CliRunner.run("vitals", "myapp", api: fake)
    expect(result.stdout).to match(/no vitals/i)
  end
end
