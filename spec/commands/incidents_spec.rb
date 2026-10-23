# frozen_string_literal: true

RSpec.describe "incidents and alert commands" do
  let(:fake) { FakeApiClient.new }
  let(:row) { { "id" => "i1", "subject_type" => "app", "app_name" => "web", "reason" => "http_5xx", "started_at" => "2026-10-23T01:00:00Z", "open" => true } }

  it "incidents lists open incidents" do
    fake.stub(:get, "/incidents?state=open", returns: [ row ])
    expect(CliRunner.run("incidents", api: fake).stdout).to include("http_5xx")
  end

  it "incidents --all --app APP filters" do
    fake.stub(:get, "/incidents?state=all&app_id=web", returns: [])
    expect(CliRunner.run("incidents", "--all", "--app", "web", api: fake).stdout).to include("No incidents")
  end

  it "incidents:info shows one" do
    fake.stub(:get, "/incidents/i1", returns: row)
    expect(CliRunner.run("incidents:info", "i1", api: fake).stdout).to include("http_5xx")
  end

  it "alerts:mutes lists mutes" do
    fake.stub(:get, "/alert_mutes", returns: [ { "id" => "m1", "app_name" => "web", "event" => nil, "until" => nil } ])
    expect(CliRunner.run("alerts:mutes", api: fake).stdout).to include("web")
  end

  it "alerts:mutes labels a permanent mute and shows a timestamp for a timed one" do
    fake.stub(:get, "/alert_mutes", returns: [
      { "id" => "m1", "app_name" => "web", "event" => nil, "until" => nil },
      { "id" => "m2", "app_name" => "api", "event" => nil, "until" => "2030-01-01T10:00:00Z" }
    ])
    out = CliRunner.run("alerts:mutes", api: fake).stdout
    expect(out).to include("(until unmuted)")
    expect(out).to include("2030-01-01T10:00:00")
  end

  it "alerts:mute --app --event --for posts an expiry" do
    fake.stub(:post, "/alert_mutes", returns: { "id" => "m2" })
    CliRunner.run("alerts:mute", "--app", "web", "--event", "app_down", "--for", "8h", api: fake)
    body = fake.calls.last.body
    expect(body).to include(app_id: "web", event: "app_down")
    expect(Time.iso8601(body[:until])).to be_within(60).of(Time.now + 8 * 3600)
  end

  it "alerts:mute without --app or --event aborts before calling the API" do
    result = CliRunner.run("alerts:mute", api: fake)
    expect(result.exit_code).not_to eq(0)
    expect(fake.calls).to be_empty
  end

  it "alerts:mute rejects a bad --for" do
    expect(CliRunner.run("alerts:mute", "--event", "app_down", "--for", "soon", api: fake).exit_code).not_to eq(0)
    expect(fake.calls).to be_empty
  end

  it "alerts:unmute DELETEs" do
    fake.stub(:delete, "/alert_mutes/m1", returns: { "message" => "Mute removed" })
    expect(CliRunner.run("alerts:unmute", "m1", api: fake).exit_code).to eq(0)
  end
end
