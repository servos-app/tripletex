module Tripletex
  # Every call authenticates with a short-lived session token. A refresh token mints one for a single company's
  # own integration; a consumer token (ours) plus an employee token (the customer's) mints one for an integration
  # sold to many companies.
  class Session
    REFRESHED_TOKEN_SECONDS = 3600

    def initialize(connection, consumer_token:, employee_token:, refresh_token:, clock: Time)
      @connection = connection
      @clock = clock
      @refresh_token = refresh_token unless missing?(refresh_token)
      @token_pair = {consumerToken: consumer_token, employeeToken: employee_token}

      if @refresh_token.nil? && @token_pair.values.any? { |token| missing?(token) }
        raise Errors::ConfigurationError, "Tripletex needs a refresh token, or a consumer token and an employee token"
      end
    end

    # A session token can expire mid-run, so a rejected one is replaced and the call tried once more. Minting
    # happens outside the rescue: a rejected mint means bad credentials, and minting again would not help.
    def authenticate
      current_token = token
      begin
        yield current_token
      rescue Errors::AuthenticationError
        @token = nil
        yield token
      end
    end

    private

    def token = @token ||= create.fetch("token")

    def create
      if @refresh_token
        post("/token/session/:createFromRefreshToken",
          refreshToken: @refresh_token, ttlSeconds: REFRESHED_TOKEN_SECONDS)
      else
        post("/token/session/:create", **@token_pair, expirationDate: expiration_date)
      end
    end

    def post(path, **body) = @connection.request(:post, path, body:).value

    # Tripletex expires the token when its Oslo clock reaches this date. Tomorrow can leave only seconds before
    # midnight; the retry in `authenticate` covers that.
    def expiration_date = OsloDate.tomorrow(@clock.now).iso8601

    def missing?(token) = token.to_s.strip.empty?
  end
end
