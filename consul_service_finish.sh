#!/bin/bash

# Extract one of the Consul servers to call the HTTP API.
export CONSUL_HTTP_SRV="$(echo $CONSUL_START_JOIN | cut -d ' ' -f 1)"

# Transition from "failed" to "left" state to prevent reconnects for 72h (as per default).
curl -XGET "http://$CONSUL_HTTP_SRV:8500/v1/agent/force-leave/$HOSTNAME"
