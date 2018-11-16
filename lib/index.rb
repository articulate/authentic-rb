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
      @clients = {}
      @well_known = '/.well-known/openid-configuration'
      valid_opts = @opts && @opts[:issWhiteList] && !@opts[:issWhiteList].empty?
      raise IncompleteOptions unless valid_opts
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
        jwt = JSON::JWT.decode token, :skip_verification
      rescue JSON::JWT::InvalidFormat
        # For sake of simplicity only exposing this error to consumers
        raise InvalidToken, 'invalid JWT format'
      end
      iss = jwt[:iss]
      raise InvalidToken, 'JWT iss was not located in provided whitelist' unless @opts[:issWhiteList].index iss

      @clients[iss] || hydrate_client(iss)

      begin
        @clients[iss].call(jwt)
      rescue JSON::JWT::UnexpectedAlgorithm, JSON::JWT::VerificationFailed
        raise InvalidToken, 'failed to valid token against JWK'
      rescue OpenSSL::PKey::PKeyError
        raise InvalidKey, 'invalid JWK'
      end
    end

    def valid_rsa_key(key)
      key['use'] == 'sig' && key['kty'] == 'RSA' && key['kid']
    end

    def valid_key(key)
      valid_rsa_key(key) && ((key['x5c'] && key['x5c'].length) || (key['n'] && key['e']))
    end

    def hydrate_client(iss)
      uri = URI.join iss, @well_known
      json = json_req uri.to_s
      body = json_req json['jwks_uri']

      raise InvalidKey, "no valid JWK found, #{json['jwks_uri']}" if body['keys'].blank?

      keys = body['keys'].select { |key| valid_key(key) }
      key_map = {}
      body['keys'].each do |key|
        key_map[key['kid']] = JSON::JWK.new(
          kty: key['kty'],
          e: key['e'],
          n: key['n'],
          kid: key['kid']
        )
      end
      @clients[iss] = proc { |jwt| jwt.verify! key_map[jwt.kid] }
    end

    def json_req(uri)
      resp = Unirest.get uri, headers: { 'Accept' => 'application/json' }
      ok = resp.code > 199 && resp.code < 300
      raise RequestError.new("failed to retrieve JWK, status #{resp.code}", resp.code) unless ok

      resp.body
    end
  end
end