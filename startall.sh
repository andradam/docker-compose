#!/bin/bash
docker-machine create -d virtualbox consul
export KV_IP=$(docker-machine ssh consul 'ifconfig eth1 | grep "inet addr:" | cut -d: -f2 | cut -d" " -f1')
eval $(docker-machine env consul)
docker run -d \
  -p ${KV_IP}:8500:8500 \
  -h consul \
  --restart always \
  gliderlabs/consul-server -bootstrap
docker-machine create -d virtualbox --swarm --swarm-master --swarm-discovery="consul://${KV_IP}:8500" --engine-opt="cluster-store=consul://${KV_IP}:8500" --engine-opt="cluster-advertise=eth1:2376" master
export MASTER_IP=$(docker-machine ssh master 'ifconfig eth1 | grep "inet addr:" | cut -d: -f2 | cut -d" " -f1')
docker-machine create -d virtualbox --swarm --swarm-discovery="consul://${KV_IP}:8500" --engine-opt="cluster-store=consul://${KV_IP}:8500" --engine-opt="cluster-advertise=eth1:2376" slave
export SLAVE_IP=$(docker-machine ssh slave 'ifconfig eth1 | grep "inet addr:" | cut -d: -f2 | cut -d" " -f1')
eval $(docker-machine env master)
docker run -d --name=registrator -h ${MASTER_IP} --volume=/var/run/docker.sock:/tmp/docker.sock gliderlabs/registrator:v6 consul://${KV_IP}:8500
eval $(docker-machine env slave)
docker run -d --name=registrator -h ${SLAVE_IP} --volume=/var/run/docker.sock:/tmp/docker.sock gliderlabs/registrator:v6 consul://${KV_IP}:8500
eval $(docker-machine env -swarm master)
docker exec bg cat /etc/nginx/nginx.conf
docker-compose up -d
docker-compose ps
