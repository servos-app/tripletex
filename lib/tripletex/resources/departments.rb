module Tripletex
  module Resources
    class Departments < Resource
      include Listable

      PATH = "/department"
    end
  end
end
