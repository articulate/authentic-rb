# frozen_string_literal: true

require 'authentic/oidc_key'

# nodoc
module Authentic
  # Internal: Key store for caching JWKs.
  class KeyStore
    # Public: cache data
    attr_reader :data, :max_age, :max_age_seconds

    def initialize(max_age, data = {})
      @data = data
      @max_age_seconds = human_time_to_seconds(max_age)
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
      data[key]&.value
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
    def set(iss, kid, new_data)
      key = get_key(iss, kid)
      data[key] = new_data.is_a?(OIDCKey) ? new_data : OIDCKey.new(new_data, max_age_seconds)
      get(iss, kid)
    end

    # Internal: Verifies if data is expired and unset it
    def expires!(key)
      unset(key) if data[key]&.expired?
    end

    # Internal: deletes data from cache
    def unset(key)
      data.delete(key)
    end

    # frozen_string_literal: true

    # Internal: converts human time to seconds for consumption of the cache service. Format example: `10h5m30s`.
    # All units are optional.
    #
    # time - time to convert, it is a string that represents time in hours, minutes, and seconds.
    #
    # Returns seconds.
    def human_time_to_seconds(time)
      m = /(?:(\d*)h)?\s?(?:(\d*)?m)?\s?(?:(\d*)?s)?/.match(time)
      h = ((m[1].to_i || 0) * 60) * 60
      mi = (m[2].to_i || 0) * 60
      s = (m[3].to_i || 0)
      h + mi + s
    end
  end
end
