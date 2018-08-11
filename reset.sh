#!/bin/bash

docker system prune
docker rmi $(docker images -q)

