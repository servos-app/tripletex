module Tripletex
  class Response
    attr_reader :status, :body

    def initialize(status:, body:, headers: {})
      @status = status
      @body = body
      @headers = headers.to_h { |name, values| [name.to_s.downcase, Array(values)] }
    end

    def success? = status.between?(200, 299)

    def data
      return @data if defined?(@data)

      @data = json? ? JSON.parse(body) : nil
    end

    def value = data&.dig("value")
    def values = data&.dig("values") || []

    def header(name) = @headers[name.downcase]&.first

    def request_id = header("x-tlx-request-id")

    private

    def json? = !body.to_s.strip.empty? && header("content-type").to_s.include?("json")
  end
end
