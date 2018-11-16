require 'json/jwt'
require 'unirest'
require 'uri'

module Authentic
  class OIDConfigError < StandardError; end
  class IncompleteOptionsError < StandardError; end

  class Validator
    def initialize(opts)
      @opts = opts
      @well_known = '/.well-known/openid-configuration'
      throw Authentic::IncompleteOptionsError unless @opts[:issWhiteList] && @opts[:issWhiteList].length
      @clients = {}
    end

    def valid(token)
      return false unless token

      jwt = JSON::JWT.decode token, :skip_verification
      iss = jwt[:iss]
      return false unless @opts[:issWhiteList].index iss

      @clients[iss] || hydrate_client(iss)
      @clients[iss].call(jwt)
    end

    def hydrate_client(iss)
      uri = URI.join iss, @well_known
      json = json_req uri.to_s
      body = json_req json['jwks_uri']

      raise Authentic::OIDConfigError unless body['keys'] && body['keys'].length

      keys = body['keys'].select { |key| key['use'] == 'sig' && key['kty'] == 'RSA' && key['kid'] && ((key['x5c'] && key['x5c'].length) || (key['n'] && key['e']))}
      key_map = {}
      keys.each do |key|
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
      resp = Unirest.get uri, headers:{ 'Accept' => 'application/json' }

      raise Authentic::OIDConfigError unless resp.code > 199 || resp.code < 300

      resp.body
    end
  end
end