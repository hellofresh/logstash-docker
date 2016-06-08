#!/bin/bash

docker-compose -f docker-compose.test.yml -p app up sut
RET=$(docker wait app_sut_1)
if [ "$RET" != "0" ]; then
        echo " Tests FAILED: $RET"
        exit 1
else
        echo " Tests PASSED"
fi
