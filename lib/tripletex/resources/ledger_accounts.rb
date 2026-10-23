module Tripletex
  module Resources
    class LedgerAccounts < Resource
      include Listable

      PATH = "/ledger/account"
    end
  end
end
