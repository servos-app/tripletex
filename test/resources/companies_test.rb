require_relative "../test_helper"

class Tripletex::Resources::CompaniesTest < Minitest::Test
  include TripletexTestHelpers

  def test_lists_the_client_companies_an_accountants_token_can_act_for
    respond_with_sessions("session-token")
    respond_with_json({values: [{id: 42}]})

    assert_equal [{"id" => 42}], tripletex_client.companies.with_login_access
    assert_tripletex_request last_request, "GET", "/company/%3EwithLoginAccess"
  end
end
