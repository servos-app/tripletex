module Tripletex
  module Resources
    class VatTypes < Resource
      include Listable

      PATH = "/ledger/vatType"
    end
  end
end
