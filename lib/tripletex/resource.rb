module Tripletex
  # Query params and bodies use Tripletex's own camelCase names (`invoiceDateFrom:`, `{"customer" => {"id" => 1}}`).
  # A call that can email the customer takes a required `send_to_customer:`, because Tripletex sends unless told not to.
  class Resource
    attr_reader :client

    def initialize(client)
      @client = client
    end

    def retrieve(id, **params) = client.get("#{path}/#{id}", params:).value

    private

    def path = self.class::PATH

    def action(id, name, **params) = client.put("#{path}/#{id}/:#{name}", params:)

    module Listable
      PAGE_SIZE = 1000

      def list(**params) = client.get(path, params:).values

      def each(**params, &)
        return enum_for(:each, **params) unless block_given?

        from = 0
        loop do
          page = list(**params, from:, count: PAGE_SIZE)
          page.each(&)
          break if page.size < PAGE_SIZE

          from += PAGE_SIZE
        end
      end
    end

    module Creatable
      def create(attributes, **params) = client.post(path, body: attributes, params:).value
    end

    # Tripletex updates with PUT but only changes the fields sent. Send the `version` read earlier to get a
    # ConflictError instead of overwriting someone else's change.
    module Updatable
      def update(id, attributes, **params) = client.put("#{path}/#{id}", body: attributes, params:).value
    end

    module Deletable
      def delete(id)
        client.delete("#{path}/#{id}")
        nil
      end
    end
  end
end
