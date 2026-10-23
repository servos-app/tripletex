module Tripletex
  module Resources
    class InvoicePaymentTypes < Resource
      include Listable

      PATH = "/invoice/paymentType"
    end
  end
end
