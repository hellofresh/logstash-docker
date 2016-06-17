#!/bin/bash

# Gracefully leave the cluster and shutdown the client.
# Reference: https://www.consul.io/docs/commands/leave.html
/usr/local/bin/consul leave
