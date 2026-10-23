module Tripletex
  module Resources
    class Customers < Resource
      include Listable
      include Creatable
      include Updatable
      include Deletable

      PATH = "/customer"
    end
  end
end
