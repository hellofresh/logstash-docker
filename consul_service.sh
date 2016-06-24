#!/bin/bash

exec /usr/local/bin/consul agent -client 127.0.0.1 -bind ${CONSUL_BIND_PRIVATE_IP} -config-dir /etc/consul.d -data-dir /var/consul/data -encrypt ${CONSUL_ENCRYPT} -dc=${CONSUL_DATACENTER} -join ${CONSUL_START_JOIN}
