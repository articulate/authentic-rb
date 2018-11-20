# frozen_string_literal: true

require 'json'
require 'spec_helper'
require 'timecop'
require 'webmock/rspec'

test_url = 'https://authentic.articulate.com/.well-known/openid-configuration'
test_jwks_url = 'https://authentic.articulate.com/v1/keys'
bad_iss = "eyJraWQiOiJEYVgxMWdBcldRZWJOSE83RU1QTUw1VnRUNEV3cmZrd2M1U2xHaVd2VXdBIiwiYWxnIjoiUlMyNTYifQ.eyJzdWIiOiIwMHV\
  kanlqc3NidDJTMVFWcjBoNyIsInZlciI6MSwiaXNzIjoiaHR0cHM6Ly9iYWQtaXNzLmNvbSIsImF1ZCI6IjBvYWRqeWs1MjNobFpmeWIxMGg3IiwiaWF0\
  IjoxNTE2NjM3MDkxLCJleHAiOjE1MTY2NDA2OTEsImp0aSI6IklELmM4amh6b2t5MGZGTlByOExfU0NycnBnVFRVeUFvY3RIdjY5T0tTbWY1R0EiLCJhb\
  XIiOlsicHdkIl0sImlkcCI6IjAwb2NnNHRidTZGSzJEaDVHMGg3Iiwibm9uY2UiOiIyIiwiYXV0aF90aW1lIjoxNTE2NjM3MDkxLCJ0ZW5hbnRJZCI6Im\
  Q0MmUzM2ZkLWYwNWUtNGE0ZS05MDUwLTViN2IyZTgwMDgzNCJ9.Senilj3Z8Z99b-UVnnxwWKjYIn4jNrE-BmZAuR7Qb3nkxS7N-r7WnAQ-4vuqtD5Fyy\
  -1zOFUxoO6jyMvhWbhNlPmYaBQk7InKZU6ABayrijfv7OJSQKzs0Q7EQbgtW4T27Gqp6G4Rp9l7O472lgwapTV_L2IUqYNP7aC3FAFcqmpP_KFyeKj-zc\
  wil6aszPgxzMA3Rp33BqQfuhIJKSYqWQT6pkDXkjM3pLxaHRfrRahQ2F0M190iCvBJMc4b82TVoQQu5uJbb1mD97wwlSvMFYCHN_51g9IY5BabZcOv4h0\
  T3-XqFxPNbS8PZVfBikumkhqD5b4zjA-3ddgPw2GkA"

token = "eyJraWQiOiJEYVgxMWdBcldRZWJOSE83RU1QTUw1VnRUNEV3cmZrd2M1U2xHaVd2VXdBIiwiYWxnIjoiUlMyNTYifQ.eyJzdWIiOiIwMHVkanl\
  qc3NidDJTMVFWcjBoNyIsInZlciI6MSwiaXNzIjoiaHR0cHM6Ly9hdXRoZW50aWMuYXJ0aWN1bGF0ZS5jb20vIiwiYXVkIjoiMG9hZGp5azUyM2hsWmZ5\
  YjEwaDciLCJpYXQiOjE1MTY2MzcwOTEsImV4cCI6MTUxNjY0MDY5MSwianRpIjoiSUQuYzhqaHpva3kwZkZOUHI4TF9TQ3JycGdUVFV5QW9jdEh2NjlPS\
  1NtZjVHQSIsImFtciI6WyJwd2QiXSwiaWRwIjoiMDBvY2c0dGJ1NkZLMkRoNUcwaDciLCJub25jZSI6IjIiLCJhdXRoX3RpbWUiOjE1MTY2MzcwOTEsIn\
  RlbmFudElkIjoiZDQyZTMzZmQtZjA1ZS00YTRlLTkwNTAtNWI3YjJlODAwODM0In0.NEVqz-jJIyaEgho3uQYOvWC52s_50AV--FHwBWm9BftucQ5G4bS\
  HL7szeaPc3HT0VrhFUntRLlJHzw7pZvRJG2WExj6HJi-Ug3LDwQOj47Gf_ywlEydBAQz7u98JK2ZJcCP16-lIOM1J-fUz-SpFqI4RcO5MLiiEPnMqsXS-\
  EkPd8Y27G64PnHnNjaY3sLrOc9peeD5Xh82TSjeMFFAPpiYNtTCixnfZeQCCtxOCPhiDYAwDSxaLbrOcDAYdO0ytKQ9dBfFoY0AzJNqgJUOPVeeC_AgEJ\
  eLIaSKVJAFqZAB8t5VagvVGIqcu7TaMCOmOZx_5A8Xc9JVmRoKDAMlizQ"

bad_token = "cyJraWQiOiJEYVgxMWdBcldRZWJOSE83RU1QTUw1VnRUNEV3cmZrd2M1U2xHaVd2VXdBIiwiYWxnIjoiUlMyNTYifQ.eyJzdWIiOiIwMHV\
  kanlqc3NidDJTMVFWcjBoNyIsInZlciI6MSwiaXNzIjoiaHR0cHM6Ly9hdXRoZW50aWMuYXJ0aWN1bGF0ZS5jb20vIiwiYXVkIjoiMG9hZGp5azUyM2hs\
  WmZ5YjEwaDciLCJpYXQiOjE1MTY2MzcwOTEsImV4cCI6MTUxNjY0MDY5MSwianRpIjoiSUQuYzhqaHpva3kwZkZOUHI4TF9TQ3JycGdUVFV5QW9jdEh2N\
  jlPS1NtZjVHQSIsImFtciI6WyJwd2QiXSwiaWRwIjoiMDBvY2c0dGJ1NkZLMkRoNUcwaDciLCJub25jZSI6IjIiLCJhdXRoX3RpbWUiOjE1MTY2MzcwOT\
  EsInRlbmFudElkIjoiZDQyZTMzZmQtZjA1ZS00YTRlLTkwNTAtNWI3YjJlODAwODM0In0.NEVqz-jJIyaEgho3uQYOvWC52s_50AV--FHwBWm9BftucQ5\
  G4bSHL7szeaPc3HT0VrhFUntRLlJHzw7pZvRJG2WExj6HJi-Ug3LDwQOj47Gf_ywlEydBAQz7u98JK2ZJcCP16-lIOM1J-fUz-SpFqI4RcO5MLiiEPnMq\
  sXS-EkPd8Y27G64PnHnNjaY3sLrOc9peeD5Xh82TSjeMFFAPpiYNtTCixnfZeQCCtxOCPhiDYAwDSxaLbrOcDAYdO0ytKQ9dBfFoY0AzJNqgJUOPVeeC_\
  AgEJeLIaSKVJAFqZAB8t5VagvVGIqcu7TaMCOmOZx_5A8Xc9JVmRoKDAMlizQ"

describe 'Authentic' do
  before do
    oidc_file = File.read('./spec/fixtures/oidc.json')
    key_file = File.read('./spec/fixtures/keys.json')
    @oidc = JSON.parse(oidc_file)
    stub_request(:get, test_url).to_return(body: oidc_file)
    stub_request(:get, test_jwks_url).to_return(body: key_file)
  end

  before(:each) do
    opts = { issWhiteList: [@oidc['issuer']], cacheMaxAge: '1m' }
    @test_instance = Authentic::Validator.new opts
  end

  describe 'init class' do
    it 'errors if no opts are provided' do
      opts = {}
      expect { Authentic::Validator.new opts }.to raise_error(Authentic::IncompleteOptions)
    end

    it 'errors if no issWhiteList urls are provided' do
      opts = { issWhiteList: [] }
      expect { Authentic::Validator.new opts }.to raise_error(Authentic::IncompleteOptions)
    end
  end

  describe '.valid' do
    it 'validates the jwt against the jwks' do
      expect(@test_instance.valid(token)).to be(true)
    end

    it 'caches the jwks client' do
      # hydrates caches
      expect(@test_instance.valid(token)).to be(true)
      expect(a_request(:get, test_url)).to have_been_made.times(1)
      expect(a_request(:get, test_jwks_url)).to have_been_made.times(1)

      # In cache and thus does not make a downstream request
      expect(@test_instance.valid(token)).to be(true)
      expect(a_request(:get, test_url)).to have_been_made.times(1)
      expect(a_request(:get, test_jwks_url)).to have_been_made.times(1)

      # Cache expires and it calls through
      t = Time.now.utc + 60
      Timecop.travel(t)
      expect(@test_instance.valid(token)).to be(true)
      expect(a_request(:get, test_url)).to have_been_made.times(2)
      expect(a_request(:get, test_jwks_url)).to have_been_made.times(2)
    end

    it 'returns false when invalid JWT is provided' do
      expect(@test_instance.valid('mercurialgoose')).to be(false)
    end

    it 'returns false with nil token' do
      expect(@test_instance.valid(nil)).to be(false)
    end

    it 'returns false when invalid iss is provided' do
      expect(@test_instance.valid(bad_iss)).to be(false)
    end
  end
  describe '.ensure_valid' do
    it 'passes valid token' do
      expect { @test_instance.ensure_valid(token) }.not_to raise_error
    end

    it 'raises error when invalid JWT is provided' do
      expect { @test_instance.ensure_valid('sillygoose') }.to raise_error(Authentic::InvalidToken)
    end

    it 'raises error with nil token' do
      expect { @test_instance.ensure_valid(nil) }.to raise_error(Authentic::InvalidToken)
    end

    it 'raises error when invalid iss is provided' do
      expect { @test_instance.ensure_valid(bad_iss) }.to raise_error(Authentic::InvalidToken)
    end

    it 'raises error when token is invalid' do
      expect { @test_instance.ensure_valid(bad_token) }.to raise_error(Authentic::InvalidToken)
    end

    it 'raises a request error when the OIDC request fails' do
      stub_request(:get, test_url).to_return(status: 500)
      expect { @test_instance.ensure_valid(token) }.to raise_error(Authentic::RequestError)
    end

    it 'raises a request error when the JWK request fails' do
      stub_request(:get, test_jwks_url).to_return(status: 500)
      expect { @test_instance.ensure_valid(token) }.to raise_error(Authentic::RequestError)
    end

    it 'raises an error when there are no valid JWKs' do
      bad_key_file = File.read('./spec/fixtures/bad_keys.json')
      stub_request(:get, test_jwks_url).to_return(body: bad_key_file)
      expect { @test_instance.ensure_valid(token) }.to raise_error(Authentic::InvalidKey)
    end

    it 'raises an error when there are no keys returned by config endpoint' do
      stub_request(:get, test_jwks_url).to_return(body: '')
      expect { @test_instance.ensure_valid(token) }.to raise_error(Authentic::InvalidKey)
    end
  end
end
