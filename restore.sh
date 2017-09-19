#!/bin/bash

num=$(ls dbdump | wc -l)
if [[ $num -gt 1 ]]; then
  echo "Error: More than one dump file"
  exit 1
elif [[ $num -lt 1 ]]; then
  echo "Error: No dump files found"
  exit 2
fi


cd dbdump/$(ls dbdump | head -1)
if [[ ! -f pg.sql ]]; then
  echo "Postgres db not found"
  exit 3
fi
if [[ ! -d graph.db ]]; then
  echo "Neo4j db not found"
  exit 4
fi

echo "Restoring postgres db..."
error=$(cat pg.sql | docker exec -i $(docker-compose ps -q postgres) psql -U apix apix_development 2>&1 > /dev/null)
if [[ ! -z "${error// }" ]]; then
  echo "$error"
  exit 5
fi

echo "Restoring neo4j db..."
docker cp graph.db/ $(docker-compose ps -q neo4j):data/databases/

echo "Done."
