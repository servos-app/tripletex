require_relative "test_helper"

class Tripletex::SessionTest < Minitest::Test
  include TripletexTestHelpers

  def test_mints_a_token_from_the_consumer_and_employee_tokens_that_expires_at_oslos_next_midnight
    respond_with_sessions("session-token")

    assert_equal "session-token", build_session(now: Time.utc(2026, 10, 4, 22, 30)).authenticate { it }
    assert_tripletex_request last_request, "POST", "/token/session/:create", auth: nil,
      body: {consumerToken: "consumer-token", employeeToken: "employee-token", expirationDate: "2026-10-06"}
  end

  def test_expires_a_winter_token_at_oslos_next_midnight
    {Time.utc(2026, 11, 4, 22, 59) => "2026-11-05", Time.utc(2026, 11, 4, 23, 0) => "2026-11-06"}.each do |now, date|
      respond_with_sessions("session-token")

      build_session(now:).authenticate { it }

      assert_equal date, JSON.parse(last_request.body).fetch("expirationDate")
    end
  end

  def test_mints_a_token_from_a_refresh_token_for_an_hour
    respond_with_sessions("session-token")
    session = build_session(consumer_token: nil, employee_token: nil, refresh_token: "tlxr_refresh")

    assert_equal "session-token", session.authenticate { it }
    assert_tripletex_request last_request, "POST", "/token/session/:createFromRefreshToken", auth: nil,
      body: {refreshToken: "tlxr_refresh", ttlSeconds: 3600}
  end

  def test_reuses_its_token_across_calls
    respond_with_sessions("first", "second")
    session = build_session

    assert_equal "first", session.authenticate { it }
    assert_equal "first", session.authenticate { it }
    assert_equal 1, requests.size
  end

  def test_needs_a_refresh_token_or_both_a_consumer_and_an_employee_token
    assert_raises(Tripletex::Errors::ConfigurationError) { build_session(employee_token: nil) }
    assert_raises(Tripletex::Errors::ConfigurationError) { build_session(consumer_token: " ") }
    assert_raises(Tripletex::Errors::ConfigurationError) do
      build_session(consumer_token: nil, employee_token: nil, refresh_token: "")
    end
  end

  def test_prefers_a_refresh_token_over_a_consumer_and_employee_token
    respond_with_sessions("session-token")

    build_session(refresh_token: "tlxr_refresh").authenticate { it }

    assert_tripletex_request last_request, "POST", "/token/session/:createFromRefreshToken", auth: nil
  end

  private

  def build_session(
    consumer_token: "consumer-token", employee_token: "employee-token", refresh_token: nil, now: Time.now
  )
    Tripletex::Session.new(
      Tripletex::Connection.new(TRIPLETEX_URL, transport:),
      consumer_token:, employee_token:, refresh_token:, clock: FixedClock.new(now)
    )
  end
end
