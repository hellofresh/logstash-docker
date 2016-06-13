require 'docker'      # see https://rubygems.org/gems/docker-api
require 'serverspec'  # see http://serverspec.org

set :backend, :exec

Excon.defaults[:write_timeout] = 1000
Excon.defaults[:read_timeout] = 1000

RSpec.configure do |config|
  # Use color in STDOUT
  config.color = true

  # Use color not only in STDOUT but also in pagers and files
  config.tty = true

  # Use the specified formatter
  config.formatter = :documentation # :progress, :html, :textmate
end

