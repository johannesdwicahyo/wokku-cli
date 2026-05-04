# frozen_string_literal: true

RSpec.describe Wokku::ApiClient do
  let(:client) { described_class.new(url: "https://example.test/api/v1", token: "tk_test") }

  it "GETs and returns parsed JSON on 200" do
    stub_request(:get, "https://example.test/api/v1/apps")
      .with(headers: { "Authorization" => "Bearer tk_test", "Content-Type" => "application/json" })
      .to_return(status: 200, body: '[{"name":"hello"}]', headers: { "Content-Type" => "application/json" })

    expect(client.get("/apps")).to eq([{ "name" => "hello" }])
  end

  it "POSTs body as JSON" do
    stub_request(:post, "https://example.test/api/v1/apps")
      .with(body: '{"name":"hi"}')
      .to_return(status: 201, body: '{"id":1,"name":"hi"}')

    expect(client.post("/apps", { name: "hi" })).to eq({ "id" => 1, "name" => "hi" })
  end

  it "raises NotAuthenticated when token is missing" do
    no_auth = described_class.new(url: "https://example.test/api/v1", token: nil)
    allow(Wokku::Config).to receive(:api_token).and_return(nil)
    expect { no_auth.get("/apps") }.to raise_error(Wokku::ApiClient::NotAuthenticated)
  end

  it "raises Error with the API's error message on 4xx" do
    stub_request(:get, "https://example.test/api/v1/templates/999")
      .to_return(status: 404, body: '{"error":"Template not found"}')

    expect { client.get("/templates/999") }.to raise_error(Wokku::ApiClient::Error, /Template not found/)
  end

  it "raises Timeout on read timeout" do
    stub_request(:get, "https://example.test/api/v1/apps").to_timeout
    expect { client.get("/apps") }.to raise_error(Wokku::ApiClient::Timeout)
  end

  it "raises Unreachable on connection refused" do
    stub_request(:get, "https://example.test/api/v1/apps").to_raise(Errno::ECONNREFUSED)
    expect { client.get("/apps") }.to raise_error(Wokku::ApiClient::Unreachable)
  end

  it "returns a friendly message on 404 from /apps/:id paths" do
    stub_request(:get, "https://example.test/api/v1/apps/missing")
      .to_return(status: 404, body: '{"error":"Couldn\'t find AppRecord"}')
    expect { client.get("/apps/missing") }.to raise_error(Wokku::ApiClient::Error, /No app named 'missing'/)
  end

  describe "#stream" do
    it "yields chunks from a successful streaming response" do
      stub_request(:get, "https://example.test/api/v1/apps/5/logs?follow=1")
        .with(headers: { "Authorization" => "Bearer tk_test" })
        .to_return(status: 200, body: "chunk1\nchunk2\n", headers: { "Content-Type" => "text/plain" })

      received = []
      client.stream(:get, "/apps/5/logs?follow=1") { |chunk| received << chunk }
      expect(received.join).to eq("chunk1\nchunk2\n")
    end

    it "raises Error on non-2xx response" do
      stub_request(:get, "https://example.test/api/v1/apps/5/logs?follow=1")
        .to_return(status: 503, body: "down")
      expect {
        client.stream(:get, "/apps/5/logs?follow=1") { |_| }
      }.to raise_error(Wokku::ApiClient::Error, /HTTP 503/)
    end

    it "raises NotAuthenticated when token is missing" do
      no_auth = described_class.new(url: "https://example.test/api/v1", token: nil)
      allow(Wokku::Config).to receive(:api_token).and_return(nil)
      expect {
        no_auth.stream(:get, "/apps/5/logs?follow=1") { |_| }
      }.to raise_error(Wokku::ApiClient::NotAuthenticated)
    end

    it "exits gracefully on Interrupt (Ctrl-C)" do
      stub_request(:get, "https://example.test/api/v1/apps/5/logs?follow=1").to_return(status: 200, body: "x")
      expect {
        client.stream(:get, "/apps/5/logs?follow=1") { |_| raise Interrupt }
      }.not_to raise_error
    end
  end
end
