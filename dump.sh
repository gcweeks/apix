#!/bin/bash

echo "Dumping postgres db..."
cd app/
docker-compose exec postgres pg_dump --clean -U postgres apixdb > ../dump_`date +%d-%m-%Y"_"%H_%M_%S`.sql
echo "Done."

