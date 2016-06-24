#
# Idea taken from: https://github.com/smartb-energy/docker-python
#

require 'spec_helper'


describe 'docker-compose.yml run' do

  #
  #  Single container tests.
  #

  describe file('/opt/logstash') do
    it { should be_directory }
  end

  # Check runit service definitions:

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

  # Heartbeats arive in intervals of 10 seconds, so we have to wait a little before querying.
  describe command('sleep 30 && curl -s -XGET http://127.0.0.1:8080/mon') do
    its(:stdout) { should match(/{"status": "ok"}/) }
  end

  # Test the negative case.
  # Expectation: If the logstash service stops functioning,
  # the logstashbrcvr service should give a 404 HTTP status code.
  describe command('sv stop logstash') do
    its(:exit_status) { should eq 0 }
  end

  describe command('sleep 20 && curl -s -XGET http://127.0.0.1:8080/mon') do
    its(:stdout) { should contain('404') }
  end

  # Consul.io agent

  describe file('/var/consul/data') do
    it { should be_directory }
  end

  describe file('/etc/consul.d') do
    it { should be_directory }
  end

  describe file('/etc/service/consul') do
    it { should be_directory }
  end

  describe file('/etc/service/consul/run') do
    it { should be_executable }
  end

  describe file('/etc/service/consul/finish') do
    it { should be_executable }
  end

  describe command('sv check consul') do
    its(:exit_status) { should eq 0 }
  end

  #
  #  Integration tests.
  #

  # Is the logstash service registered in the Consul service catalog?
  describe command('sleep 30 && curl --fail -XGET http://consul-server:8500/v1/catalog/service/logstash') do
    its(:exit_status) { should_not eq 22 }
  end

  # Is the logstash service registered in the Consul service catalog with the defined port from /etc/consul.d/logstash.json?
  describe command('curl -s -XGET http://consul-server:8500/v1/catalog/service/logstash | jq -c ".[0] | {LogstashPort: .ServicePort}"') do
    its(:stdout) { should match(/{"LogstashPort":5044}/) }
  end

  # Stop the consul agent. This executes '/etc/service/consul/finish' which calls the Consul HTTP API to indicate a force-leave of the agent node.
  # system("sv stop consul")
  describe command('sv stop consul') do
    its(:exit_status) { should eq 0 }
  end

  # The logstash service should now be vanished since the Consul node is gone.
  describe command('sleep 20 && curl -s -XGET http://consul-server:8500/v1/health/service/logstash?passing | jq -c ". | length"') do
    its(:stdout) { should match(/0/) }
  end


end # describe 'docker-compose.yml run' do