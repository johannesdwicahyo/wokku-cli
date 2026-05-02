# frozen_string_literal: true

RSpec.describe "wokku version" do
  it "prints wokku/<VERSION>" do
    result = CliRunner.run("version")
    expect(result.exit_code).to eq(0)
    expect(result.stdout).to match(%r{wokku/\d+\.\d+\.\d+})
  end
end
