module Tripletex
  module Errors
    class Error < StandardError; end

    class ConfigurationError < Error; end

    class ConnectionError < Error; end

    class TimeoutError < Error; end

    class ApiError < Error
      attr_reader :response

      def initialize(response)
        @response = response
        super(summary)
      end

      def status = response.status

      def request_id = response.request_id

      # Tripletex's own error code, finer than the HTTP status: 8000 is a stale `version`, 18000 a failed validation.
      def code = details["code"]

      def validation_messages = details["validationMessages"] || []

      def details = response.data.is_a?(Hash) ? response.data : {}

      private

      # Names the invalid fields but not Tripletex's text about them, which can echo the customer data we sent;
      # exception messages reach AppSignal. `request_id` is what Tripletex support looks up.
      def summary
        fields = validation_messages.filter_map { |validation| validation["field"] }
        [
          "Tripletex responded #{status}",
          ("code #{code}" if code),
          ("request #{request_id}" if request_id),
          ("invalid #{fields.join(", ")}" if fields.any?)
        ].compact.join(", ")
      end
    end

    class BadRequestError < ApiError; end

    class AuthenticationError < ApiError; end

    class ForbiddenError < ApiError; end

    class NotFoundError < ApiError; end

    # An edit conflict: a stale `version`, a duplicate, or a state that forbids the change.
    class ConflictError < ApiError; end

    class ValidationError < ApiError; end

    class RateLimitError < ApiError
      def retry_after = response.header("x-rate-limit-reset")&.to_i
    end

    class ServerError < ApiError; end

    STATUSES = {
      400 => BadRequestError,
      401 => AuthenticationError,
      403 => ForbiddenError,
      404 => NotFoundError,
      409 => ConflictError,
      422 => ValidationError,
      429 => RateLimitError
    }.freeze

    def self.for(response)
      error_class = STATUSES.fetch(response.status) { (response.status >= 500) ? ServerError : ApiError }
      error_class.new(response)
    end
  end
end
