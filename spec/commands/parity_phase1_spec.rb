# frozen_string_literal: true

RSpec.describe "parity phase 1 commands" do
  let(:fake) { FakeApiClient.new }

  it "transfers lists incoming and outgoing" do
    fake.stub(:get, "/app_transfers", returns: {
      "incoming" => [ { "id" => "t1", "app_name" => "shop", "from_email" => "a@x.io", "expires_at" => "2026-11-08" } ],
      "outgoing" => [ { "id" => "t2", "app_name" => "blog", "to_email" => "b@x.io", "expires_at" => "2026-11-08" } ]
    })
    result = CliRunner.run("transfers", api: fake)
    expect(result.stdout).to match(/t1\s+incoming\s+shop\s+from a@x\.io/)
    expect(result.stdout).to match(/t2\s+outgoing\s+blog\s+to b@x\.io/)
  end

  it "transfers:accept POSTs accept" do
    fake.stub(:post, "/app_transfers/t1/accept", returns: { "app_name" => "shop" })
    result = CliRunner.run("transfers:accept", "t1", api: fake)
    expect(result.exit_code).to eq(0)
    expect(result.stdout).to match(/shop is now yours/)
  end

  it "transfers:decline POSTs decline" do
    fake.stub(:post, "/app_transfers/t1/decline", returns: { "status" => "declined" })
    expect(CliRunner.run("transfers:decline", "t1", api: fake).exit_code).to eq(0)
  end

  it "transfers:cancel DELETEs the transfer" do
    fake.stub(:delete, "/app_transfers/t2", returns: { "status" => "cancelled" })
    expect(CliRunner.run("transfers:cancel", "t2", api: fake).stdout).to match(/cancelled/i)
  end

  it "teams:members:role PATCHes the role" do
    fake.stub(:patch, "/teams/T/members/M", returns: { "email" => "b@x.io", "role" => "viewer" })
    result = CliRunner.run("teams:members:role", "T", "M", "viewer", api: fake)
    expect(fake.calls.first.body).to eq(role: "viewer")
    expect(result.stdout).to match(/b@x\.io is now viewer/)
  end

  it "notifications:test POSTs test" do
    fake.stub(:post, "/notifications/N/test", returns: { "message" => "Test email notification queued" })
    expect(CliRunner.run("notifications:test", "N", api: fake).stdout).to match(/queued/)
  end

  it "databases:resize PATCHes the new shape" do
    fake.stub(:patch, "/databases/pg/resize", returns: { "message" => "Resizing pg" })
    result = CliRunner.run("databases:resize", "pg", "--cpu", "0.5", "--memory", "1024", "--disk", "10", api: fake)
    expect(fake.calls.first.body).to eq(cpu: "0.5", memory_mb: 1024, disk_gb: 10)
    expect(result.stdout).to match(/Resizing pg/)
  end

  it "databases:resize aborts without all three sizes" do
    expect(CliRunner.run("databases:resize", "pg", "--cpu", "0.5", api: fake).exit_code).not_to eq(0)
  end

  it "databases:retry POSTs retry" do
    fake.stub(:post, "/databases/pg/retry", returns: { "message" => "Retrying provisioning for pg" })
    expect(CliRunner.run("databases:retry", "pg", api: fake).stdout).to match(/Retrying/)
  end

  it "billing:invoices lists invoices with a pay link for unpaid ones" do
    fake.stub(:get, "/billing/invoices", returns: [
      { "reference" => "INV-1", "period" => "Nov 2026", "amount_idr" => 75_000, "status" => "pending", "pay_url" => "https://wokku.cloud/dashboard/invoices/1" },
      { "reference" => "INV-0", "period" => "Oct 2026", "amount_idr" => 1_500_000, "status" => "paid", "pay_url" => nil }
    ])
    result = CliRunner.run("billing:invoices", api: fake)
    expect(result.stdout).to match(%r{INV-1\s+Nov 2026\s+Rp75\.000\s+pending\s+pay: https://wokku\.cloud/dashboard/invoices/1})
    expect(result.stdout).to match(/INV-0\s+Oct 2026\s+Rp1\.500\.000\s+paid$/)
  end
end
