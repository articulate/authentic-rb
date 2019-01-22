# frozen_string_literal: true

require 'json/jwt'
require 'rest-client'
require 'authentic/key_store'

module Authentic
  # Internal: manages JWK retrieval, caching, and validation.
  class KeyManager
    attr_reader :store, :well_known

    def initialize(max_age)
      @store = KeyStore.new(max_age)
      @well_known = '/.well-known/openid-configuration'
    end

    # Public: retrieves JWK.
    #
    # jwt - JSON::JWT.
    #
    # Returns JSON::JWK.
    def get(jwt)
      iss = jwt.fetch(:iss)

      result = store.get(iss, jwt.kid)

      return result unless result.nil?

      # Refresh all keys for an issuer while I have the updated data on hand
      hydrate_iss_keys iss
      store.get(iss, jwt.kid)
    end

    # Internal: validates RSA key.
    #
    # key - hash with key data.
    #
    # Returns boolean.
    def valid_rsa_key(key)
      key['use'] == 'sig' && key['kty'] == 'RSA' && key['kid']
    end

    # Internal: performs JSON request.
    #
    # key - hash with JWK data.
    #
    # Returns boolean.
    def valid_key(key)
      valid_rsa_key(key) && (key['x5c']&.length || (key['n'] && key['e']))
    end

    # Internal: performs JSON request.
    #
    # uri - endpoint to request.
    #
    # Returns JSON.
    def json_req(uri)
      begin
        resp = RestClient.get(uri, accept: :json)
      rescue RestClient::ExceptionWithResponse => e
        code = e.response.code
        raise RequestError.new("failed to retrieve JWK, status #{code}", code)
      end

      JSON.parse resp.body
    end

    # Internal: hydrates JWK cache.
    #
    # iss - issuer URI.
    #
    # Returns nothing.
    def hydrate_iss_keys(iss)
      uri = iss.sub(%r{[\/]+$}, '') + well_known
      json = json_req uri.to_s
      body = json_req json['jwks_uri']

      raise InvalidKey, "no valid JWK found, #{json['jwks_uri']}" if body['keys']&.blank?

      keys = body['keys'].select { |key| valid_key(key) }
      hydrate_store(keys, iss)
    end

    # Internal: hydrates key store.
    #
    # keys - array of keys hash.
    # iss - JWT issuer endpoint.
    #
    # Returns nothing.
    def hydrate_store(keys, iss)
      keys.each do |key|
        store.set(
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
