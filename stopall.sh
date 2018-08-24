#!/bin/bash
docker-machine stop consul master slave
echo yes | docker-machine rm consul master slave
unset ${!DOCKER*}
