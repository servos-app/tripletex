require_relative "../test_helper"

class Tripletex::Resources::OrdersTest < Minitest::Test
  include TripletexTestHelpers

  def test_invoices_an_order_without_sending_the_invoice
    respond_with_sessions("session-token")
    respond_with_json({value: {id: 99}})

    invoice = tripletex_client.orders.invoice(7, invoice_date: Date.new(2026, 10, 4), send_to_customer: false)

    assert_equal({"id" => 99}, invoice)
    assert_tripletex_request last_request, "PUT", "/order/7/:invoice",
      query: {invoiceDate: "2026-10-04", sendToCustomer: "false"}
  end
end
