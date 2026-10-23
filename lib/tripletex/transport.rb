module Tripletex
  module Transport
    def self.perform(request, timeout:, open_timeout:)
      uri = request.uri

      Net::HTTP.start(
        uri.host, uri.port,
        use_ssl: uri.scheme == "https", read_timeout: timeout, open_timeout: open_timeout
      ) do |http|
        response = http.request(request)
        Response.new(status: response.code.to_i, body: response.body, headers: response.to_hash)
      end
    end
  end
end
