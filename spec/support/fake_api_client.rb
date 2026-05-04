# frozen_string_literal: true

# In-memory replacement for Wokku::ApiClient. Pre-stage responses with `stub`,
# inspect calls via `calls`. Raises Wokku::ApiClient::Error on a staged failure.
class FakeApiClient
  Call = Struct.new(:method, :path, :body, keyword_init: true)

  attr_reader :calls

  def initialize
    @calls = []
    @stubs = {}
  end

  def stub(method, path, returns: nil, raises: nil)
    @stubs[[method, path]] = { returns: returns, raises: raises }
    self
  end

  %i[get post put patch delete].each do |verb|
    define_method(verb) do |path, body = nil|
      request(verb, path, body)
    end
  end

  def request(method, path, body = nil)
    @calls << Call.new(method: method, path: path, body: body)
    key = [method, path]
    stub = @stubs[key]
    raise Wokku::ApiClient::Error, "No stub for #{method.upcase} #{path}" unless stub
    raise stub[:raises] if stub[:raises]
    stub[:returns]
  end

  def stream(method, path, &block)
    @calls << Call.new(method: method, path: path, body: nil)
    key = [method, path]
    stub = @stubs[key]
    raise Wokku::ApiClient::Error, "No stub for stream #{method.upcase} #{path}" unless stub
    Array(stub[:returns]).each { |chunk| block.call(chunk) }
  end
end
