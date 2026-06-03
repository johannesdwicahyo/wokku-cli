# frozen_string_literal: true

RSpec.describe "tunnel command" do
  let(:fake) { FakeApiClient.new }
  let(:create_payload) do
    {
      "tunnel_id"  => "tid",
      "token"      => "plain-token",
      "frps_host"  => "jkt-01.wokku.cloud",
      "frps_port"  => 7000,
      "public_url" => "https://abc12345.wokku.dev",
      "subdomain"  => "abc12345",
      "watermark"  => true,
      "expires_at" => (Time.now + 7200).iso8601
    }
  end

  before do
    fake.stub(:post,   "/tunnels",     returns: create_payload)
    fake.stub(:delete, "/tunnels/tid", returns: nil)
    # Pretend frpc is already installed so the spec doesn't try to download.
    allow(File).to receive(:executable?).and_call_original
    allow(File).to receive(:executable?).with(/\.wokku\/bin\/frpc\z/).and_return(true)
    # Don't actually exec frpc.
    allow_any_instance_of(Object).to receive(:system).and_return(true)
  end

  it "POSTs to /tunnels with the local port and exits 0" do
    result = CliRunner.run("tunnel", "3000", api: fake)
    expect(result.exit_code).to eq(0)
    create_call = fake.calls.find { |c| c.path == "/tunnels" && c.method == :post }
    expect(create_call).to be_truthy
  end

  it "passes --subdomain through to the API" do
    CliRunner.run("tunnel", "3000", "--subdomain", "mything", api: fake)
    create_call = fake.calls.find { |c| c.path == "/tunnels" && c.method == :post }
    expect(create_call.body[:subdomain]).to eq("mything")
  end

  it "passes --app through to the API" do
    CliRunner.run("tunnel", "3000", "--app", "myapp-id", api: fake)
    create_call = fake.calls.find { |c| c.path == "/tunnels" && c.method == :post }
    expect(create_call.body[:app_record_id]).to eq("myapp-id")
  end

  it "DELETEs the session after frpc exits" do
    CliRunner.run("tunnel", "3000", api: fake)
    delete_call = fake.calls.find { |c| c.path == "/tunnels/tid" && c.method == :delete }
    expect(delete_call).to be_truthy
  end

  it "aborts when PORT is missing" do
    result = CliRunner.run("tunnel", api: fake)
    expect(result.exit_code).not_to eq(0)
  end

  it "aborts when PORT is not a positive integer" do
    result = CliRunner.run("tunnel", "0", api: fake)
    expect(result.exit_code).not_to eq(0)
  end

  it "aborts cleanly when the API returns an error envelope" do
    fake.stub(:post, "/tunnels", returns: { "error" => "tunnel limit reached", "code" => "tunnel_limit_reached" })
    result = CliRunner.run("tunnel", "3000", api: fake)
    expect(result.exit_code).not_to eq(0)
    expect("#{result.stdout}#{result.stderr}").to match(/tunnel limit reached/i)
  end
end
