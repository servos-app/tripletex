require_relative "lib/tripletex/version"

Gem::Specification.new do |spec|
  spec.name = "tripletex"
  spec.version = Tripletex::VERSION
  spec.authors = ["SERVOS"]
  spec.email = ["a@asgerbehnckejacobsen.dk"]

  spec.summary = "Ruby client for the Tripletex accounting API (v2)"
  spec.description = "A client for the Tripletex API v2 (tripletex.no/v2-docs). Plain Ruby, no runtime dependencies."
  spec.homepage = "https://github.com/servos-app/tripletex"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.4"

  spec.files = Dir["lib/**/*.rb"]
  spec.require_paths = ["lib"]
end
