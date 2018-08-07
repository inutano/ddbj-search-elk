#!/bin/sh

# Set variables
ES_HOST=${ES_HOST:-localhost}
ES_PORT=${ES_PORT:-9200}

id=${1}
json_path=${2}

curl -s --header "Content-Type:application/json" -XPUT ${ES_HOST}:${ES_PORT}/sra/_doc/${1} -d @${2}
