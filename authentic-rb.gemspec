# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)

Gem::Specification.new do |s|
  s.name    = 'authentic-rb'
  s.version = '1.0.2'
  s.authors = ['Articulate', 'Andy Gertjejansen']
  s.summary = 'validation of JWTs against JWKs'
  s.description = 'Ruby toolkit for Auth0 API https://auth0.com.'
  s.homepage    = 'https://rubygems.org/gems/authentic-rb'
  s.metadata    = { 'source_code_uri' => 'https://github.com/articulate/authentic-rb' }
  s.files       = Dir.glob("lib/**/*")

  s.add_runtime_dependency 'json-jwt', '~> 1.9', '>= 1.9.4'
  s.add_runtime_dependency 'unirest', '~> 1.1.2', '>= 1.1.2'
end
