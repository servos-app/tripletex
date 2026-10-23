require_relative "test_helper"

class Tripletex::ClientTest < Minitest::Test
  include TripletexTestHelpers

  def test_authenticates_as_the_token_owners_company_with_the_session_token
    respond_with_sessions("session-token")
    respond_with_json({value: {companyId: 7}})

    assert_equal({"companyId" => 7}, tripletex_client.whoami)
    assert_tripletex_request last_request, "GET", "/token/session/%3EwhoAmI"
  end

  def test_authenticates_as_the_client_company_an_accountants_token_acts_for
    respond_with_sessions("session-token")
    respond_with_json({value: {companyId: 42}})

    assert_equal({"companyId" => 42}, tripletex_client(company_id: 42).whoami)
    assert_tripletex_request last_request, "GET", "/token/session/%3EwhoAmI", auth: ["42", "session-token"]
  end

  def test_talks_to_tripletexs_production_environment_by_default
    respond_with_sessions("session-token")
    respond_with_json({value: {id: 1}})

    tripletex_client.customers.retrieve(1)

    assert_equal ["tripletex.no"], requests.map { |request| request.uri.host }.uniq
  end

  def test_talks_to_tripletexs_test_environment
    respond_with_sessions("session-token")
    respond_with_json({value: {id: 1}})

    assert_equal({"id" => 1}, tripletex_client(environment: :test).customers.retrieve(1))
    assert_equal ["api-test.tripletex.tech"], requests.map { |request| request.uri.host }.uniq
    assert_tripletex_request requests.first, "POST", "/token/session/:create", auth: nil
    assert_tripletex_request last_request, "GET", "/customer/1"
  end

  def test_rejects_an_unknown_environment
    assert_raises(Tripletex::Errors::ConfigurationError) { tripletex_client(environment: :staging) }
  end

  def test_mints_a_fresh_session_token_and_retries_once_when_tripletex_rejects_the_current_one
    respond_with_sessions("expired")
    respond_with_json({status: 401}, status: 401)
    respond_with_sessions("fresh")
    respond_with_json({value: {id: 1}})

    assert_equal({"id" => 1}, tripletex_client.customers.retrieve(1))
    assert_tripletex_request requests[1], "GET", "/customer/1", auth: ["0", "expired"]
    assert_tripletex_request requests[2], "POST", "/token/session/:create", auth: nil
    assert_tripletex_request requests[3], "GET", "/customer/1", auth: ["0", "fresh"]
    assert_equal 4, requests.size
  end

  def test_raises_when_tripletex_rejects_the_fresh_session_token_too
    respond_with_sessions("expired")
    respond_with_json({status: 401}, status: 401)
    respond_with_sessions("fresh")
    respond_with_json({status: 401}, status: 401)

    assert_raises(Tripletex::Errors::AuthenticationError) { tripletex_client.customers.retrieve(1) }
    assert_equal 4, requests.size
  end

  def test_raises_without_retrying_when_tripletex_rejects_the_tokens_it_mints_sessions_from
    respond_with_json({status: 401}, status: 401)

    assert_raises(Tripletex::Errors::AuthenticationError) { tripletex_client.customers.retrieve(1) }
    assert_equal 1, requests.size
    assert_tripletex_request last_request, "POST", "/token/session/:create", auth: nil
  end
end
