require_relative "../test_helper"

class Tripletex::Resources::VouchersTest < Minitest::Test
  include TripletexTestHelpers

  def test_reverses_a_voucher_on_a_date
    respond_with_sessions("session-token")
    respond_with_json({value: {id: 13}})

    assert_equal({"id" => 13}, tripletex_client.vouchers.reverse(12, date: Date.new(2026, 10, 4)))
    assert_tripletex_request last_request, "PUT", "/ledger/voucher/12/:reverse", query: {date: "2026-10-04"}
  end
end
