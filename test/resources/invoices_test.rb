require_relative "../test_helper"

class Tripletex::Resources::InvoicesTest < Minitest::Test
  include TripletexTestHelpers

  def setup
    respond_with_sessions("session-token")
    @invoices = tripletex_client.invoices
  end

  def test_creates_an_invoice_without_sending_it
    respond_with_json({value: {id: 99}}, status: 201)

    assert_equal({"id" => 99}, @invoices.create({invoiceDate: "2026-10-04"}, send_to_customer: false))
    assert_tripletex_request last_request, "POST", "/invoice",
      query: {sendToCustomer: "false"}, body: {invoiceDate: "2026-10-04"}
  end

  def test_registers_a_payment
    respond_with_json({value: {id: 99, amountOutstanding: 0}})

    invoice = @invoices.register_payment(99,
      payment_date: Date.new(2026, 10, 4), payment_type_id: 5, paid_amount: 1250.0)

    assert_equal 0, invoice["amountOutstanding"]
    assert_tripletex_request last_request, "PUT", "/invoice/99/:payment",
      query: {paymentDate: "2026-10-04", paymentTypeId: "5", paidAmount: "1250.0"}
  end

  def test_credits_an_invoice_without_sending_the_credit_note
    respond_with_json({value: {id: 100}})

    assert_equal({"id" => 100}, @invoices.create_credit_note(99, date: Date.new(2026, 10, 4), send_to_customer: false))
    assert_tripletex_request last_request, "PUT", "/invoice/99/:createCreditNote",
      query: {date: "2026-10-04", sendToCustomer: "false"}
  end

  def test_sends_an_invoice_to_the_customer
    transport.respond_with(status: 200)

    assert_nil @invoices.deliver(99, send_type: "EMAIL")
    assert_tripletex_request last_request, "PUT", "/invoice/99/:send", query: {sendType: "EMAIL"}
  end

  def test_downloads_an_invoice_as_pdf
    transport.respond_with(body: "%PDF-1.7", headers: {"Content-Type" => "application/pdf"})

    assert_equal "%PDF-1.7", @invoices.pdf(99)
    assert_tripletex_request last_request, "GET", "/invoice/99/pdf"
  end
end
