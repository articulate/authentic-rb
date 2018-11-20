# frozen_string_literal: true

# nodoc
module Authentic
  # Internal: JWKs cache data.
  class OIDCKey
    attr_reader :expires, :value

    def initialize(value, max_age_seconds)
      @value = value
      @expires = max_age_seconds.nil? ? nil : Time.now.utc + max_age_seconds
    end

    def expired?
      !expires.nil? && Time.now.utc > expires
    end
  end
end
