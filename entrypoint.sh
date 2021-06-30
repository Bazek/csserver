#!/bin/bash -e

./csserver start

tail -n +1 -f /home/csserver/log/console/csserver-console.log
