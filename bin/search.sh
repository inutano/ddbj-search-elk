#!/bin/sh

# Set variables
ES_HOST=${ES_HOST:-localhost}
ES_PORT=${ES_PORT:-9200}

curl -s --header "Content-Type:application/json" -XPOST ${ES_HOST}:${ES_PORT}/_search -d '
{
  "query": {
    "bool": {
      "must": { "match_all": {} },
      "filter": {
        "match": {"sra.study.STUDY.@accession": "DRP000001"}
      }
    }
  }
}'
