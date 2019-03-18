# frozen_string_literal: true

# nodoc
module Authentic
  # Public: Represents a request error when requesting OIDC config or JWKs from authorization server.
  class RequestError < StandardError
    attr_reader :code
    def initialize(msg, code)
      @code = code
      super(msg)
    end
  end

  # Public: Represents an error with JWK.
  class InvalidKey < StandardError; end

  # Public: Represents a error with options passed to Authentic::Validator.
  class IncompleteOptions < StandardError; end

  # Public: Represents a bad JWT.
  class InvalidToken < StandardError; end

  # Public: Represents an expired JWT.
  class ExpiredToken < StandardError; end

  # Public: Represents an issuer that is not whitelisted. This should produce a 403 response.
  class InvalidIssuer < StandardError; end
end
