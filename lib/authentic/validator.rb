# frozen_string_literal: true

require 'authentic/error'
require 'authentic/key_manager'

# Public: proper validation of JWTs against JWKs.
module Authentic
  # Public: validates JWTs against JWKs.
  class Validator
    attr_reader :iss_whitelist, :manager, :opts

    def initialize(options = {})
      @iss_whitelist = options.fetch(:iss_whitelist) { [] }
      raise IncompleteOptions if iss_whitelist.empty?

      max_age = options.fetch(:cache_max_age) { '10h' }
      @manager = options.fetch(:key_manager) { KeyManager.new(max_age) }
    end

    # Public: validates JWT, returns true if valid, false if not.
    #
    # token - raw JWT.
    #
    # Returns boolean.
    def valid?(token)
      ensure_valid(token)
      true
    rescue InvalidToken, ExpiredToken, InvalidKey, RequestError, InvalidIssuer
      false
    end

    # Public: validates JWT, raises an error for invalid JWTs, errors requesting JWKs,
    # the lack of valid JWKs, or non white listed ISS.
    #
    # token - raw JWT.
    #
    # Returns nothing.
    def ensure_valid(token)
      decode_jwt(token).tap do |jwt|
        key = manager.get(jwt)

        # Slightly more accurate to raise a key error here for nil key,
        # rather then verify raising an error that would lead to InvalidToken
        raise InvalidKey if key.nil?

        exp = Time.at(jwt[:exp])
        raise ExpiredToken, "Token expired at #{exp}" unless exp > Time.now

        jwt.verify!(key)
      end
    rescue JSON::JWT::UnexpectedAlgorithm, JSON::JWT::VerificationFailed
      raise InvalidToken, 'Failed to validate token against JWK'
    rescue OpenSSL::PKey::PKeyError
      raise InvalidKey
    end

    # Decodes and does basic validation of JWT.
    #
    # token - raw JWT.
    #
    # Returns JSON::JWT
    def decode_jwt(token)
      raise InvalidToken, 'JWT was nil' unless token

      JSON::JWT.decode(token, :skip_verification).tap do |jwt|
        raise InvalidIssuer, 'JWT iss was not located in provided whitelist' unless iss_whitelist.include?(jwt[:iss])
      end
    rescue JSON::JWT::InvalidFormat
      raise InvalidToken, 'JWT was in an invalid format'
    end
  end
end
