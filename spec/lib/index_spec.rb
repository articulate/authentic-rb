require 'json'
require 'spec_helper'

well_known = '/.well-known/openid-configuration'
bad_iss = 'eyJraWQiOiJEYVgxMWdBcldRZWJOSE83RU1QTUw1VnRUNEV3cmZrd2M1U2xHaVd2VXdBIiwiYWxnIjoiUlMyNTYifQ.eyJzdWIiOiIwMHVkanlqc3NidDJTMVFWcjBoNyIsInZlciI6MSwiaXNzIjoiaHR0cHM6Ly9iYWQtaXNzLmNvbSIsImF1ZCI6IjBvYWRqeWs1MjNobFpmeWIxMGg3IiwiaWF0IjoxNTE2NjM3MDkxLCJleHAiOjE1MTY2NDA2OTEsImp0aSI6IklELmM4amh6b2t5MGZGTlByOExfU0NycnBnVFRVeUFvY3RIdjY5T0tTbWY1R0EiLCJhbXIiOlsicHdkIl0sImlkcCI6IjAwb2NnNHRidTZGSzJEaDVHMGg3Iiwibm9uY2UiOiIyIiwiYXV0aF90aW1lIjoxNTE2NjM3MDkxLCJ0ZW5hbnRJZCI6ImQ0MmUzM2ZkLWYwNWUtNGE0ZS05MDUwLTViN2IyZTgwMDgzNCJ9.Senilj3Z8Z99b-UVnnxwWKjYIn4jNrE-BmZAuR7Qb3nkxS7N-r7WnAQ-4vuqtD5Fyy-1zOFUxoO6jyMvhWbhNlPmYaBQk7InKZU6ABayrijfv7OJSQKzs0Q7EQbgtW4T27Gqp6G4Rp9l7O472lgwapTV_L2IUqYNP7aC3FAFcqmpP_KFyeKj-zcwil6aszPgxzMA3Rp33BqQfuhIJKSYqWQT6pkDXkjM3pLxaHRfrRahQ2F0M190iCvBJMc4b82TVoQQu5uJbb1mD97wwlSvMFYCHN_51g9IY5BabZcOv4h0T3-XqFxPNbS8PZVfBikumkhqD5b4zjA-3ddgPw2GkA'
token = 'eyJraWQiOiJEYVgxMWdBcldRZWJOSE83RU1QTUw1VnRUNEV3cmZrd2M1U2xHaVd2VXdBIiwiYWxnIjoiUlMyNTYifQ.eyJzdWIiOiIwMHVkanlqc3NidDJTMVFWcjBoNyIsInZlciI6MSwiaXNzIjoiaHR0cHM6Ly9hdXRoZW50aWMuYXJ0aWN1bGF0ZS5jb20vIiwiYXVkIjoiMG9hZGp5azUyM2hsWmZ5YjEwaDciLCJpYXQiOjE1MTY2MzcwOTEsImV4cCI6MTUxNjY0MDY5MSwianRpIjoiSUQuYzhqaHpva3kwZkZOUHI4TF9TQ3JycGdUVFV5QW9jdEh2NjlPS1NtZjVHQSIsImFtciI6WyJwd2QiXSwiaWRwIjoiMDBvY2c0dGJ1NkZLMkRoNUcwaDciLCJub25jZSI6IjIiLCJhdXRoX3RpbWUiOjE1MTY2MzcwOTEsInRlbmFudElkIjoiZDQyZTMzZmQtZjA1ZS00YTRlLTkwNTAtNWI3YjJlODAwODM0In0.NEVqz-jJIyaEgho3uQYOvWC52s_50AV--FHwBWm9BftucQ5G4bSHL7szeaPc3HT0VrhFUntRLlJHzw7pZvRJG2WExj6HJi-Ug3LDwQOj47Gf_ywlEydBAQz7u98JK2ZJcCP16-lIOM1J-fUz-SpFqI4RcO5MLiiEPnMqsXS-EkPd8Y27G64PnHnNjaY3sLrOc9peeD5Xh82TSjeMFFAPpiYNtTCixnfZeQCCtxOCPhiDYAwDSxaLbrOcDAYdO0ytKQ9dBfFoY0AzJNqgJUOPVeeC_AgEJeLIaSKVJAFqZAB8t5VagvVGIqcu7TaMCOmOZx_5A8Xc9JVmRoKDAMlizQ'

describe 'Authentic.create' do
  before {
    oidc_file = File.read('./spec/fixtures/oidc.json')
    key_file = File.read('./spec/fixtures/keys.json')
    @oidc = JSON.parse(oidc_file)
    stub_request(:get, 'https://authentic.articulate.com/.well-known/openid-configuration').to_return(body: oidc_file)
    stub_request(:get, 'https://authentic.articulate.com/v1/keys').to_return(body: key_file)
  }

  describe 'with a valid jwt' do
    before(:each) do
      opts = { issWhiteList: [@oidc['issuer']] }
      @test_instance = Authentic::Validator.new opts
    end

    it 'validates the jwt against the jwks' do
      expect(@test_instance.valid(token)).to be(true)
    end

    it 'caches the jwks client' do
      expect(@test_instance.valid(token)).to be(true)
    end
  end
end
