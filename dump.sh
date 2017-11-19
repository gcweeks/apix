#!/bin/bash

dir=$(date "+%d-%m-%Y_%H_%M_%S")
mkdir -p dbdump/$dir

echo "Dumping postgres db..."
cd app/
docker-compose exec postgres pg_dump --clean -U postgres apixdb > ../dbdump/$dir/pg.sql

echo "Copying Neo4j db..."
docker cp $(docker-compose ps -q neo4j):data/databases/graph.db/ ../dbdump/$dir/

echo "Done."
