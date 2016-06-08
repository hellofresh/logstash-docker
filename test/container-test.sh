#!/bin/bash

# give logstash some time to startup
sleep 30
curl -s -XGET 'http://127.0.0.1:8080/mon' | grep '{"status": "ok"}'
