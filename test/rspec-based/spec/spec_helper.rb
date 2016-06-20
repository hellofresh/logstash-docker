
require 'serverspec'  # see http://serverspec.org
require 'specinfra/backend/docker_compose'

set :docker_compose_file, '../../docker-compose.yml'
set :docker_compose_container, :logstash # The compose container to test
set :docker_wait, 15 # wait 15 seconds before running the tests
set :backend, :docker_compose

###set :backend, :exec

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

