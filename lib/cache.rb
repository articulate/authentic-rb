# frozen_string_literal: true

# Internal: cache related classes for Authentic JWKs cache.
module Cache
  # Internal: JWKs cache data.
  class OIDCKey
    attr_reader :value
    attr_reader :expires

    def initialize(value, max_age_seconds)
      @value = value
      @expires = max_age_seconds.nil? ? nil : Time.now.utc + max_age_seconds
    end

    def expired?
      !@expires.nil? && Time.now.utc > @expires
    end
  end

  # Internal: Key store for caching JWKs.
  class KeyStore
    # Public: cache data
    attr_reader :data

    def initialize(max_age, data = {})
      @data = data
      @max_age_seconds = human_time_to_seconds max_age
    end

    # Public: Sets data, and wraps it in OIDCKey class if not presented as that type.
    #
    # iss - issuer
    # kid - key id
    #
    # Returns JSON::JWK
    def get(iss, kid)
      key = get_key(iss, kid)
      expires!(key)
      @data[key]&.value
    end

    # Internal: builds cache key
    #
    # iss - issuer
    # kid - key id
    #
    # Returns string
    def get_key(iss, kid)
      "#{iss}/#{kid}"
    end

    # Public: Sets data, and wraps it in OIDCKey class if not presented as that type.
    #
    # iss - issuer
    # kid - key id
    # data - data to cache which is usually a single OIDC public key.
    #
    # Returns JSON::JWK
    def set(iss, kid, data)
      key = get_key(iss, kid)
      @data[key] = data.is_a?(OIDCKey) ? data : OIDCKey.new(data, @max_age_seconds)
      get(iss, kid)
    end

    # Internal: Verifies if data is expired and unset it
    def expires!(key)
      unset(key) if @data[key]&.expired?
    end

    # Internal: deletes data from cache
    def unset(key)
      @data.delete(key)
    end
  end
end
