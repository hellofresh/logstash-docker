#
# Idea taken from: https://github.com/smartb-energy/docker-python
#

require 'spec_helper'

# Tag of the image to use for tests.
IMAGE_TAG = 'wespi-0.4'


describe "Dockerfile" do
  before(:all) do
    image = Docker::Image.create(fromImage: "quay.io/hellofresh/logstash-docker:#{IMAGE_TAG}") do |v|
      if (log = JSON.parse(v)) && log.has_key?("stream")
        $stdout.puts log["stream"]
      end
    end

    set :os, family: :debian
    set :backend, :docker
    set :docker_image, image.id

  end

  # after(:all) do
  #   image.remove(:force => true)
  # end


  describe file('/opt/logstash') do
    it { should be_directory }
  end

  #
  # Check runit service definitions:
  #
  describe file('/etc/service/logstash') do
    it { should be_executable }
  end

  describe file('/etc/service/logstashbrcvr/run') do
    it { should be_executable }
  end

  # Give logstash service some time to spin up.
  describe command('sleep 30 && sv check logstash') do
    its(:exit_status) { should eq 0 }
  end

  describe command('sv check logstash') do
    its(:stdout) { should match(/ok: run: logstash/) }
  end

  describe command('sv check logstashbrcvr') do
    its(:exit_status) { should eq 0 }
  end

  describe command('sv check logstashbrcvr') do
    its(:stdout) { should match(/ok: run: logstashbrcvr/) }
  end

  describe command('curl -s -XGET http://127.0.0.1:8080/mon') do
    its(:stdout) { should match(/{"status": "ok"}/) }
  end

  # Test the negative case.
  # Expectation: If the logstash service stops functioning,
  # the logstashbrcvr service should give a 404 HTTP status code.
  `sv stop logstash && sleep 10`

  describe command('curl -s -XGET http://127.0.0.1:8080/mon') do
    its(:stdout) { should contain('404') }
  end

end
