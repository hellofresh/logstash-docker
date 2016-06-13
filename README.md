[![Build Status](https://travis-ci.org/hellofresh/logstash-docker.svg?branch=master)](https://travis-ci.org/hellofresh/logstash-docker)

==============

# logstash-docker
Docker-ized Logstash service with runit supervision.

Also includes Logstash monitoring with the help of the Logstash [heartbeat input plugin]() and a small Golang utility called [`logstashbrcvr`](https://github.com/hellofresh/logstashbrcvr).

### How to run the tests

      cd test/rspec-based
      bundle install --path ./vendor/bundle
      bundle exec rspec

