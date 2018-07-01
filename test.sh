#!/bin/bash

docker-compose -f docker-compose.test.yml up --exit-code-from web-test --abort-on-container-exit --force-recreate
rc=$?
if [ $rc -ne 0 ]; then
  echo "Tests failed!"
fi

exit $rc
