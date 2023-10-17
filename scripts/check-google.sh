#!/usr/bin/env bash

set -eu

response_code=$(curl -s -o /dev/null -w "%{http_code}" https://www.google.com)

if [ "$response_code" -eq 200 ]; then
  echo "Can reach google.com with a HTTP 200 response, we're good to go!"
else
  echo "Can't reach google.com (HTTP response code: $response_code). Run curl -vvv https://www.google.com to debug."
fi

