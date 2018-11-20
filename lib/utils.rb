# frozen_string_literal: true

# Internal: converts human time to seconds for consumption of the cache service. Format ``
#
# human_time - represents time in hours, minutes, and seconds.
#
# Returns seconds.
def human_time_to_seconds(human_time)
  m = /(?:(\d*)h)?\s?(?:(\d*)?m)?\s?(?:(\d*)?s)?/.match(human_time)
  h = ((m[1].to_i || 0) * 60) * 60
  mi = (m[2].to_i || 0) * 60
  s = (m[3].to_i || 0)
  h + mi + s
end
