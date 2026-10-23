require "date"
require "json"
require "net/http"
require "openssl"
require "time"
require "uri"

require_relative "tripletex/version"
require_relative "tripletex/errors"
require_relative "tripletex/response"
require_relative "tripletex/transport"
require_relative "tripletex/connection"
require_relative "tripletex/oslo_date"
require_relative "tripletex/session"
require_relative "tripletex/resource"
Dir[File.join(__dir__, "tripletex/resources/*.rb")].each { |file| require file }
require_relative "tripletex/client"

# Ruby client for the Tripletex accounting API v2 (https://tripletex.no/v2-docs).
module Tripletex
end
