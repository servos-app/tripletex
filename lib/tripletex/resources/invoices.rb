module Tripletex
  module Resources
    class Invoices < Resource
      include Listable
      include Creatable

      PATH = "/invoice"

      def create(attributes, send_to_customer:, **params)
        super(attributes, sendToCustomer: send_to_customer, **params)
      end

      # `paid_amount` is in the currency of the payment type's ledger account, despite the spec's summary saying the
      # invoice's. A foreign-currency invoice also needs `paidAmountCurrency:` in its own currency.
      def register_payment(id, payment_date:, payment_type_id:, paid_amount:, **params)
        action(id, :payment,
          paymentDate: payment_date, paymentTypeId: payment_type_id, paidAmount: paid_amount, **params).value
      end

      def create_credit_note(id, date:, send_to_customer:, **params)
        action(id, :createCreditNote, date:, sendToCustomer: send_to_customer, **params).value
      end

      def deliver(id, send_type:, **params)
        action(id, :send, sendType: send_type, **params)
        nil
      end

      def pdf(id) = client.get("#{PATH}/#{id}/pdf").body
    end
  end
end
