require "minitest/autorun"
require "bigdecimal"
require_relative "../lib/tripletex"

class FakeTransport
  attr_reader :requests

  def initialize
    @requests = []
    @responses = []
  end

  def respond_with(status: 200, body: nil, headers: {})
    @responses << Tripletex::Response.new(status:, body:, headers:)
    self
  end

  def fail_with(error)
    @responses << error
    self
  end

  def perform(request, timeout:, open_timeout:)
    @requests << request
    response = @responses.shift || Tripletex::Response.new(status: 200, body: nil, headers: {})
    raise response if response.is_a?(Exception)

    response
  end
end

FixedClock = Struct.new(:now)

module TripletexTestHelpers
  TRIPLETEX_URL = "https://tripletex.no/v2"

  private

  def transport = @transport ||= FakeTransport.new

  def requests = transport.requests

  def last_request = requests.last

  def tripletex_client(**)
    Tripletex::Client.new(consumer_token: "consumer-token", employee_token: "employee-token", transport:, **)
  end

  def respond_with_sessions(*tokens)
    tokens.each { |token| respond_with_json({value: {token:}}, status: 201) }
  end

  def respond_with_json(body, status: 200, headers: {})
    transport.respond_with(
      status:, body: body.to_json,
      headers: {"Content-Type" => "application/json", "x-tlx-request-id" => "req-1", **headers}
    )
  end

  # `path` is as it goes on the wire, after `/v2` and with `>` escaped; `query` lists every parameter sent.
  def assert_tripletex_request(request, method, path, query: {}, auth: ["0", "session-token"], body: nil)
    assert_equal method, request.method
    assert_equal "/v2#{path}", request.uri.path
    assert_equal query.to_h { |name, value| [name.to_s, value] }, URI.decode_www_form(request.uri.query.to_s).to_h
    assert_authorization auth, request
    assert_equal JSON.parse(body.to_json), JSON.parse(request.body) if body
  end

  def assert_authorization(auth, request)
    if auth
      assert_equal "Basic #{[auth.join(":")].pack("m0")}", request["Authorization"]
    else
      assert_nil request["Authorization"]
    end
  end
end
