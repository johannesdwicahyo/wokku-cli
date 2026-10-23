# frozen_string_literal: true

require "tempfile"

RSpec.describe "upload helpers" do
  describe "upload_presigned" do
    it "PUTs the archive without an Authorization header" do
      Tempfile.create("a.tar.gz") do |f|
        f.write("tgz")
        f.flush
        stub = stub_request(:put, "https://bucket.test/k?sig=1")
          .with { |req| req.headers["Authorization"].nil? && req.body == "tgz" }
          .to_return(status: 200)
        expect(upload_presigned("https://bucket.test/k?sig=1", f.path)).to be(true)
        expect(stub).to have_been_requested
      end
    end

    it "aborts on a failed upload" do
      Tempfile.create("a.tar.gz") do |f|
        stub_request(:put, "https://bucket.test/k").to_return(status: 403)
        expect { upload_presigned("https://bucket.test/k", f.path) }.to raise_error(SystemExit)
      end
    end
  end

  describe "build_tarball" do
    it "archives a non-git directory without node_modules" do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, "app.rb"), "puts 1")
        FileUtils.mkdir_p(File.join(dir, "node_modules"))
        File.write(File.join(dir, "node_modules", "big.js"), "x")
        archive = File.join(dir, "..", "out-#{rand(1_000_000)}.tar.gz")
        build_tarball(dir, archive)
        listing = IO.popen([ "tar", "-tzf", archive ], &:read)
        expect(listing).to include("app.rb")
        expect(listing).not_to include("node_modules")
      ensure
        FileUtils.rm_f(archive) if archive
      end
    end
  end
end
