require 'faraday'
require 'json'

module JsonApiClient
  autoload :Resource, 'json_api_client/resource'
  autoload :Scope, 'json_api_client/scope'
  autoload :Query, 'json_api_client/query'
  autoload :Parser, 'json_api_client/parser'
end