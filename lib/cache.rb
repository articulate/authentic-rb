module Cache
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

  class KeyStore
    attr_reader :data

    def initialize(max_age, data = {})
      @data = data
      @max_age_seconds = human_time_to_seconds max_age
    end

    def get(iss, kid)
      key = get_key(iss, kid)
      expires!(key)
      @data[key]&.value
    end

    def get_key(iss, kid)
      "#{iss}/#{kid}"
    end

    def set(iss, kid, data)
      key = get_key(iss, kid)
      @data[key] = data.is_a?(OIDCKey) ? data : OIDCKey.new(data, @max_age_seconds)
      get(iss, kid)
    end

    def expires!(key)
      unset(key) if @data[key]&.expired?
    end

    def unset(key)
      @data.delete(key)
    end
  end
end