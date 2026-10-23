module Tripletex
  module Resources
    class Products < Resource
      include Listable
      include Creatable
      include Updatable
      include Deletable

      PATH = "/product"
    end
  end
end
