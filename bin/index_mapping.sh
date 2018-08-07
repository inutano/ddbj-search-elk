#!/bin/sh

# Set variables
ES_HOST=${ES_HOST:-localhost}
ES_PORT=${ES_PORT:-9200}

curl -s --header "Content-Type:application/json" -XPUT ${ES_HOST}:${ES_PORT}/sra -d '{
  "settings": {
    "index": {
      "number_of_shards": 1,
      "number_of_replicas": 0
    }
  }
}'
