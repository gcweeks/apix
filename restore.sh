#!/bin/bash


num=$(find . -maxdepth 1 -name "dump_*" | wc -l)
if [ $num -gt 1 ]; then
  echo "Error: More than one dump file"
  exit 1
elif [ $num -lt 1 ]; then
  echo "Error: No dump files found"
  exit 2
fi

echo "Restoring..."

cat dump_* | docker exec -i $(docker-compose ps -q postgres) psql -U apix apix_development

echo "Done."

