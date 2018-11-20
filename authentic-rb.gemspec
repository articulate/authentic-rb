$LOAD_PATH.push File.expand_path('lib', __dir__)

Gem::Specification.new do |s|
  s.name    = 'authentic-rb'
  s.version = '0.0.1'
  s.authors = ['Articulate', 'Andy Gertjejansen']
  s.summary = 'validation of JWTs against JWKs'
  s.description = 'Ruby toolkit for Auth0 API https://auth0.com.'

  s.add_runtime_dependency 'json-jwt', '~> 1.9', '>= 1.9.4'
  s.add_runtime_dependency 'unirest', '~> 1.1', '>= 1.1.2'
end
