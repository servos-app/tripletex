module Tripletex
  class Connection
    HTTP_METHODS = {
      get: Net::HTTP::Get,
      post: Net::HTTP::Post,
      put: Net::HTTP::Put,
      delete: Net::HTTP::Delete
    }.freeze
    TIMEOUTS = {timeout: 30, open_timeout: 10}.freeze

    def initialize(base_url, transport: Transport)
      @base_url = base_url
      @transport = transport
    end

    def request(method, path, params: {}, body: nil, basic_auth: nil)
      http_request = HTTP_METHODS.fetch(method).new(build_uri(path, params))
      http_request.basic_auth(*basic_auth) if basic_auth

      if body
        http_request["Content-Type"] = "application/json"
        http_request.body = body.to_json
      end

      perform(http_request).tap do |response|
        raise Errors.for(response) unless response.success?
      end
    end

    private

    def perform(http_request)
      @transport.perform(http_request, **TIMEOUTS)
    rescue Net::OpenTimeout, Net::ReadTimeout => error
      raise Errors::TimeoutError, error.message
    rescue SocketError, SystemCallError, OpenSSL::SSL::SSLError => error
      raise Errors::ConnectionError, error.message
    end

    # Summary paths such as `/token/session/>whoAmI` carry a `>`, which a URI must escape.
    def build_uri(path, params)
      uri = URI("#{@base_url}#{URI::RFC2396_PARSER.escape(path)}")
      query = params.compact.transform_values { |value| query_value(value) }
      uri.query = URI.encode_www_form(query) if query.any?
      uri
    end

    def query_value(value)
      case value
      when Array then value.join(",")
      when Time then value.getutc.iso8601
      when DateTime then value.to_time.getutc.iso8601
      else decimal?(value) ? value.to_s("F") : value
      end
    end

    # BigDecimal is a gem of its own, not loaded here: a caller who passes one has loaded it.
    def decimal?(value) = defined?(BigDecimal) && value.is_a?(BigDecimal)
  end
end
