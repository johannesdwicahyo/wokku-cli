# frozen_string_literal: true

RSpec.describe Wokku::Config do
  describe ".api_url" do
    it "is always wokku.cloud" do
      expect(described_class.api_url).to eq("https://wokku.cloud/api/v1")
    end

    it "ignores a WOKKU_API_URL env override (managed cloud only)" do
      original = ENV["WOKKU_API_URL"]
      ENV["WOKKU_API_URL"] = "https://evil.test/api/v1"
      expect(described_class.api_url).to eq("https://wokku.cloud/api/v1")
    ensure
      ENV["WOKKU_API_URL"] = original
    end

    it "ignores an api_url saved in config" do
      described_class.save("api_url" => "https://stale.test/api/v1", "token" => "tk")
      expect(described_class.api_url).to eq("https://wokku.cloud/api/v1")
    ensure
      File.delete(described_class.file) if File.exist?(described_class.file)
    end
  end
end
