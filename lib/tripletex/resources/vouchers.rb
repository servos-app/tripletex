module Tripletex
  module Resources
    # Tripletex books a voucher's postings from their gross amounts only, and expects those rounded to two decimals.
    class Vouchers < Resource
      include Listable
      include Creatable
      include Updatable
      include Deletable

      PATH = "/ledger/voucher"

      def reverse(id, date:) = action(id, :reverse, date:).value
    end
  end
end
