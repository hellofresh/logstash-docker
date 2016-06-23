#!/bin/bash

# Transition from "failed" to "left" state to prevent reconnects for 72h (as per default).
curl -XGET "http://consul-server:8500/v1/agent/force-leave/$HOSTNAME"
