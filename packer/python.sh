#!/bin/bash
while [ 1 ]; do
    apt-get update
    if [ $? -eq 0 ]; then
        break
    fi
    sleep 5
done
apt-get install -y --no-install-recommends python python-pip python-setuptools
