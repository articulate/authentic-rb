require 'json/jwt'
require 'unirest'
require 'uri'

module Authentic
  class RequestError < StandardError
    attr_reader :code
    def initialize(msg, code)
      @code = code
      super(msg)
    end
  end

  class InvalidKey < StandardError; end
  class IncompleteOptions < StandardError; end
  class InvalidToken < StandardError; end

  class Validator
    def initialize(opts)
      @opts = opts
      valid_opts = @opts && @opts[:issWhiteList] && !@opts[:issWhiteList].empty?
      raise IncompleteOptions unless valid_opts

      @manager = KeyManager.new @opts[:cacheMaxAge]
    end

    # Validates token, returns true if valid, false if not.
    def valid(token)
      begin
        ensure_valid token
      rescue InvalidToken, InvalidKey, RequestError
        return false
      end

      true
    end

    # Validates token, raises an error for invalid JWTs, errors requesting JWKs,
    # the lack of valid JWKs, or non white listed ISS.
    def ensure_valid(token)
      raise InvalidToken, 'invalid nil JWT provided' unless token

      begin
        jwt = JSON::JWT.decode(token, :skip_verification)
      rescue JSON::JWT::InvalidFormat
        # For sake of simplicity only exposing this error to consumers
        raise InvalidToken, 'invalid JWT format'
      end
      iss = jwt[:iss]
      raise InvalidToken, 'JWT iss was not located in provided whitelist' unless @opts[:issWhiteList].index iss

      begin
        key = @manager.get jwt

        # Slightly more accurate to raise a key error here for nil key,
        # rather then verify raising an error that would lead to InvalidToken
        raise InvalidKey, 'invalid JWK' unless key != nil

        jwt.verify! key
      rescue JSON::JWT::UnexpectedAlgorithm, JSON::JWT::VerificationFailed
        raise InvalidToken, 'failed to validate token against JWK'
      rescue OpenSSL::PKey::PKeyError
        raise InvalidKey, 'invalid JWK'
      end
    end
  end

  class KeyManager
    def initialize(max_age)
      @store = Cache::KeyStore.new(max_age || '10h')
      @well_known = '/.well-known/openid-configuration'
    end

    def get(jwt)
      iss = jwt[:iss]

      result = @store.get(iss, jwt.kid)

      return result unless result.nil?

      # Refresh all keys for an issuer while I have the updated data on hand
      hydrate_iss_keys iss
      @store.get(iss, jwt.kid)
    end

    def valid_rsa_key(key)
      key['use'] == 'sig' && key['kty'] == 'RSA' && key['kid']
    end

    def valid_key(key)
      valid_rsa_key(key) && ((key['x5c'] && key['x5c'].length) || (key['n'] && key['e']))
    end

    def json_req(uri)
      resp = Unirest.get uri, headers: { 'Accept' => 'application/json' }
      ok = resp.code > 199 && resp.code < 300
      raise RequestError.new("failed to retrieve JWK, status #{resp.code}", resp.code) unless ok

      resp.body
    end

    def hydrate_iss_keys(iss)
      uri = URI.join iss, @well_known
      json = json_req uri.to_s
      body = json_req json['jwks_uri']

      raise InvalidKey, "no valid JWK found, #{json['jwks_uri']}" if body['keys'].blank?

      keys = body['keys'].select { |key| valid_key(key) }
      keys.each do |key|
        @store.set(
          iss, key['kid'],
          JSON::JWK.new(
            kty: key['kty'],
            e: key['e'],
            n: key['n'],
            kid: key['kid']
          )
        )
      end
    end
  end
end
