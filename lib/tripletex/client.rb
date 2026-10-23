module Tripletex
  class Client
    ENVIRONMENTS = {
      production: "https://tripletex.no/v2",
      test: "https://api-test.tripletex.tech/v2"
    }.freeze

    # `company_id` 0 is the token owner's own company; an accountant's token names a client company instead.
    def initialize(
      consumer_token: nil, employee_token: nil, refresh_token: nil, company_id: 0, environment: :production,
      transport: Transport
    )
      base_url = ENVIRONMENTS.fetch(environment.to_sym) do
        raise Errors::ConfigurationError, "Unknown Tripletex environment #{environment}"
      end
      @connection = Connection.new(base_url, transport:)
      @session = Session.new(@connection, consumer_token:, employee_token:, refresh_token:)
      @company_id = company_id.to_s
    end

    def companies = @companies ||= Resources::Companies.new(self)
    def customers = @customers ||= Resources::Customers.new(self)
    def departments = @departments ||= Resources::Departments.new(self)
    def invoice_payment_types = @invoice_payment_types ||= Resources::InvoicePaymentTypes.new(self)
    def invoices = @invoices ||= Resources::Invoices.new(self)
    def ledger_accounts = @ledger_accounts ||= Resources::LedgerAccounts.new(self)
    def orders = @orders ||= Resources::Orders.new(self)
    def products = @products ||= Resources::Products.new(self)
    def vat_types = @vat_types ||= Resources::VatTypes.new(self)
    def vouchers = @vouchers ||= Resources::Vouchers.new(self)

    def whoami = get("/token/session/>whoAmI").value

    def get(path, **) = request(:get, path, **)
    def post(path, **) = request(:post, path, **)
    def put(path, **) = request(:put, path, **)
    def delete(path, **) = request(:delete, path, **)

    private

    def request(method, path, **)
      @session.authenticate { |token| @connection.request(method, path, basic_auth: [@company_id, token], **) }
    end
  end
end
