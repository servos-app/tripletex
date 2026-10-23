module Tripletex
  module Resources
    class Orders < Resource
      include Listable
      include Creatable
      include Updatable
      include Deletable

      PATH = "/order"

      def invoice(id, invoice_date:, send_to_customer:, **params)
        action(id, :invoice, invoiceDate: invoice_date, sendToCustomer: send_to_customer, **params).value
      end
    end
  end
end
