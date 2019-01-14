# frozen_string_literal: true

require 'authentic/error'
require 'authentic/key_manager'

# Public: proper validation of JWTs against JWKs.
module Authentic
  # Public: validate JWTs against JWKs using iss whitelist in an environment variable.
  #
  # token - raw JWT.
  # opts  - Optionally pass configuration options.
  #
  # Returns boolean.
  def self.valid?(token, opts = {})
    Validator.configure(opts) unless opts.empty?
    Validator.new.valid?(token)
  end

  # Public: uses environment variable for iss whitelist and validates JWT,
  # raises an error for invalid JWTs, errors requesting JWKs, the lack of valid JWKs, or non white listed ISS.
  #
  # token - raw JWT.
  # opts  - Optionally pass configuration options.
  #
  # Returns nothing.
  def self.ensure_valid(token, opts = {})
    Validator.configure(opts) unless opts.empty?
    Validator.new.ensure_valid(token)
  end

  # Public: validates JWTs against JWKs.
  class Validator
    @@manager = KeyManager.new('10h')
    @@iss_whitelist = []

    # Public: Configures iss_whitelist and cache_max_age
    #
    # opts - options to configure the validator with
    #
    # Returns nothing.
    def self.configure(opts)
      @@iss_whitelist = opts[:iss_whitelist]
      @@manager.cache_max_age(opts.fetch(:cache_max_age, '10h'))
    end

    def initialize
      # Default iss whitelist if it is empty
      @@iss_whitelist = @@iss_whitelist&.empty? ? ENV['ISS_WHITELIST']&.split('|') : @@iss_whitelist

      valid_opts = !@@iss_whitelist&.empty?
      raise IncompleteOptions unless valid_opts
    end

    # Private: resets key manager cache
    def reset_cache
      @@manager.store.reset_all
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
        key = @@manager.get jwt

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
        raise InvalidToken, 'JWT iss was not located in provided whitelist' unless @@iss_whitelist.index jwt[:iss]
      end
    rescue JSON::JWT::InvalidFormat
      raise InvalidToken, 'invalid JWT format'
    end
  end
end
