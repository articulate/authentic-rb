# frozen_string_literal: true

require 'authentic/error'
require 'authentic/key_manager'

# Public: proper validation of JWTs against JWKs.
module Authentic
  # Public: validate JWTs against JWKs using iss whitelist in an environment variable.
  #
  # token - raw JWT.
  #
  # Returns boolean.
  def self.valid?(token)
    Validator.new.valid?(token)
  end

  # Public: uses environment variable for iss whitelist and validates JWT,
  # raises an error for invalid JWTs, errors requesting JWKs, the lack of valid JWKs, or non white listed ISS.
  #
  # token - raw JWT.
  #
  # Returns nothing.
  def self.ensure_valid(token)
    Validator.new.ensure_valid(token)
  end

  # Public: validates JWTs against JWKs.
  class Validator
    attr_reader :iss_whitelist, :manager, :opts

    def initialize(options = {})
      @opts = options
      @iss_whitelist = opts.fetch(:iss_whitelist) { ENV['AUTHENTIC_ISS_WHITELIST']&.split(',') }
      valid_opts = !iss_whitelist&.empty?
      raise IncompleteOptions unless valid_opts

      @manager = KeyManager.new opts[:cache_max_age]
    end

    # Public: validates JWT, returns true if valid, false if not.
    #
    # token - raw JWT.
    #
    # Returns boolean.
    def valid?(token)
      ensure_valid token
      true
    rescue InvalidToken, InvalidKey, RequestError
      false
    end

    # Public: validates JWT, raises an error for invalid JWTs, errors requesting JWKs,
    # the lack of valid JWKs, or non white listed ISS.
    #
    # token - raw JWT.
    #
    # Returns nothing.
    def ensure_valid(token)
      jwt = decode_jwt token

      begin
        key = manager.get jwt

        # Slightly more accurate to raise a key error here for nil key,
        # rather then verify raising an error that would lead to InvalidToken
        raise InvalidKey, 'invalid JWK' if key.nil?

        jwt.verify! key
      rescue JSON::JWT::UnexpectedAlgorithm, JSON::JWT::VerificationFailed
        raise InvalidToken, 'failed to validate token against JWK'
      rescue OpenSSL::PKey::PKeyError
        raise InvalidKey, 'invalid JWK'
      end
    end

    # Decodes and does basic validation of JWT.
    #
    # token - raw JWT.
    #
    # Returns JSON::JWT
    def decode_jwt(token)
      raise InvalidToken, 'invalid nil JWT provided' unless token

      JSON::JWT.decode(token, :skip_verification).tap do |jwt|
        raise InvalidToken, 'JWT iss was not located in provided whitelist' unless iss_whitelist.index jwt[:iss]
      end
    rescue JSON::JWT::InvalidFormat
      raise InvalidToken, 'invalid JWT format'
    end
  end
end