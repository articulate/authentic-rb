# frozen_string_literal: true

require 'pry'

require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
end

require 'codecov'
SimpleCov.formatter = SimpleCov::Formatter::Codecov if ENV['TRAVIS']

require 'dotenv'
Dotenv.load

require 'webmock/rspec'
WebMock.allow_net_connect!

$LOAD_PATH.unshift File.expand_path('.', __dir__)
$LOAD_PATH.unshift File.expand_path('lib', __dir__)

Dir['./lib/**/*.rb'].each { |f| require f }

require 'rspec'
RSpec.configure do |config|
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
end

def wait(time, increment = 5, elapsed_time = 0, &block)
  yield
rescue RSpec::Expectations::ExpectationNotMetError => e
  raise e if elapsed_time >= time

  sleep increment
  wait(time, increment, elapsed_time + increment, &block)
end

def entity_suffix
  'rubytest'
end

puts "Entity suffix is #{entity_suffix}"
