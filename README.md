# authentic-rb

Ruby clone of [@authentic/authentic](https://github.com/articulate/authentic). A simple library to validate JWTs against JWKs.

## Installation

``` bash
gem install authentic-rb
```

... or with [Bundler](https://bundler.io/man/bundle-add.1.html):

```bash
bundle add authentic-rb
```

## Usage

Instantiate `Authentic::Validator` with an options hash, which must contain an `iss_whitelist` array listing the `token.payload.iss` values you will accept. For example:

| Provider | Sample `iss_whitelist` |
| -------- | ------------------- |
| [Auth0](https://auth0.com/) | `[ 'https://${tenant}.auth0.com/' ]` |
| [Okta](https://www.okta.com/) | `[ 'https://${tenant}.oktapreview.com/oauth2/${authServerId}' ]` |

There are two basic entry points for validation. `ensure_valid` and `valid`. `valid` basically wraps `ensure_valid`, catches any errors it raises, and returns a simple boolean for those that prefer that idiom. Here are some examples of both:

```ruby
require 'authentic'

# For this method to work we must set the environment variable AUTHENTIC_ISS_WHITELIST as a comma delimited string
ENV['AUTHENTIC_ISS_WHITELIST'] = 'https://articulate.auth0.com/,https://articulate.oktapreview.com/oauth2/default'
valid = Authentic.valid?(request.cookies[:token])

# Or if we want the errors to bubble up
Authentic.ensure_valid(request.cookies[:token])

# Manually pass in iss_whitelist
opts = { iss_whitelist: ['https://articulate.auth0.com/'] }
validator = Authentic::Validator.new opts

# Simply returns true or false based on validity
valid = validator.valid?(request.cookies[:token])

# Raises errors when it cannot validate a given token.
begin
    validator.ensure_valid(request.cookies[:token])
rescue InvalidToken, InvalidKey, RequestError => e
    # do stuff
end
```

## Options

Instantiate `Authentic::Validator` with an options hash, which must contain an `iss_whitelist` array listing the `token.payload.iss` values you will accept. For example:

| Name            | Default | Required | Notes                                                        |
| --------------- | ------- | -------- | -------------------------------------------------------------|
| iss_whitelist   | N/A     | y        |                                                              |
| cache_max_age   | `'10h'` | n        | Supports seconds, minutes, and hours. Example `'10h 30m 60s'`|