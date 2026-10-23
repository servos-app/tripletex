module Tripletex
  module Resources
    class Companies < Resource
      PATH = "/company"

      # The client companies an accountant's token can act for, as `company_id` on the client.
      def with_login_access(**params) = client.get("#{PATH}/>withLoginAccess", params:).values
    end
  end
end
