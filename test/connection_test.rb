require_relative "test_helper"

class Tripletex::ConnectionTest < Minitest::Test
  include TripletexTestHelpers

  def setup
    @connection = Tripletex::Connection.new(TRIPLETEX_URL, transport:)
  end

  def test_sends_lists_as_comma_separated_query_values_and_leaves_out_nil_ones
    respond_with_json({values: [{id: 1}]})

    response = @connection.request(:get, "/customer",
      params: {id: [1, 2], invoiceDateFrom: Date.new(2026, 10, 4), email: nil})

    assert_equal [{"id" => 1}], response.values
    assert_tripletex_request last_request, "GET", "/customer", auth: nil,
      query: {id: "1,2", invoiceDateFrom: "2026-10-04"}
  end

  def test_sends_times_as_utc_iso_8601_without_changing_the_callers_time
    respond_with_json({values: []})
    changed_since = Time.new(2026, 9, 26, 10, 0, 0, "+02:00")

    @connection.request(:get, "/customer", params: {changedSince: changed_since})

    assert_tripletex_request last_request, "GET", "/customer", auth: nil, query: {changedSince: "2026-09-26T08:00:00Z"}
    assert_equal 2 * 3600, changed_since.utc_offset
  end

  def test_sends_date_times_as_utc_iso_8601
    respond_with_json({values: []})

    @connection.request(:get, "/customer", params: {changedSince: DateTime.new(2026, 9, 26, 10, 0, 0, "+02:00")})

    assert_tripletex_request last_request, "GET", "/customer", auth: nil, query: {changedSince: "2026-09-26T08:00:00Z"}
  end

  def test_sends_decimals_without_an_exponent
    respond_with_json({value: {id: 1}})

    response = @connection.request(:put, "/invoice/1/:payment", params: {paidAmount: BigDecimal("1250.50")})

    assert_equal({"id" => 1}, response.value)
    assert_tripletex_request last_request, "PUT", "/invoice/1/:payment", auth: nil, query: {paidAmount: "1250.5"}
  end

  def test_sends_the_body_as_json
    respond_with_json({value: {id: 1}}, status: 201)

    assert_equal({"id" => 1}, @connection.request(:post, "/customer", body: {name: "Fjellstua"}).value)
    assert_equal({name: "Fjellstua"}.to_json, last_request.body)
    assert_equal "application/json", last_request["Content-Type"]
  end

  def test_sends_basic_auth
    @connection.request(:get, "/customer", basic_auth: ["0", "session-token"])

    assert_tripletex_request last_request, "GET", "/customer"
  end

  def test_raises_the_error_class_for_each_status_tripletex_documents
    Tripletex::Errors::STATUSES.merge(503 => Tripletex::Errors::ServerError, 418 => Tripletex::Errors::ApiError)
      .each do |status, error_class|
        respond_with_json({status:}, status:)

        error = assert_raises(Tripletex::Errors::ApiError) { @connection.request(:get, "/customer") }
        assert_instance_of error_class, error
        assert_equal status, error.status
      end
  end

  def test_names_the_invalid_fields_in_the_error_message_but_leaves_out_tripletexs_text_about_them
    respond_with_json({
      status: 422, code: 18000, message: "Validering feilet.",
      validationMessages: [{field: "email", message: "guest@example.com er ikke en gyldig e-post"}]
    }, status: 422)

    error = assert_raises(Tripletex::Errors::ValidationError) { @connection.request(:post, "/customer", body: {}) }

    assert_equal "Tripletex responded 422, code 18000, request req-1, invalid email", error.message
    assert_equal "guest@example.com er ikke en gyldig e-post", error.validation_messages.first["message"]
  end

  def test_raises_server_error_when_a_proxy_answers_with_an_html_page
    transport.respond_with(status: 502, body: "<html>Bad Gateway</html>", headers: {"Content-Type" => "text/html"})

    error = assert_raises(Tripletex::Errors::ServerError) { @connection.request(:get, "/customer") }

    assert_equal "Tripletex responded 502", error.message
  end

  def test_tells_a_rate_limited_caller_how_many_seconds_remain_in_the_period
    respond_with_json({status: 429}, status: 429, headers: {"X-Rate-Limit-Reset" => "17"})

    error = assert_raises(Tripletex::Errors::RateLimitError) { @connection.request(:get, "/customer") }

    assert_equal 17, error.retry_after
  end

  def test_raises_timeout_error_when_tripletex_does_not_answer_in_time
    [Net::OpenTimeout, Net::ReadTimeout].each do |timeout|
      transport.fail_with(timeout.new)

      assert_raises(Tripletex::Errors::TimeoutError) { @connection.request(:get, "/customer") }
    end
  end

  def test_raises_connection_error_when_tripletex_cannot_be_reached
    [SocketError, Errno::ECONNREFUSED, OpenSSL::SSL::SSLError].each do |failure|
      transport.fail_with(failure.new)

      assert_raises(Tripletex::Errors::ConnectionError) { @connection.request(:get, "/customer") }
    end
  end

  def test_reaches_the_network_through_net_http_by_default
    connection = Tripletex::Connection.new("http://127.0.0.1:1/v2")

    assert_raises(Tripletex::Errors::ConnectionError) { connection.request(:get, "/customer") }
  end
end
