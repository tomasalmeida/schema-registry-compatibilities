#!/bin/bash

#clean
docker-compose down -v

# Start cluster
docker-compose up -d

# Wait mainZookeeper is UP
ZOOKEEPER_STATUS=""
while [[ $ZOOKEEPER_STATUS != "imok" ]]; do
  echo "Waiting zookeeper UP..."
  sleep 1
  ZOOKEEPER_STATUS=$(echo ruok | docker-compose exec mainZookeeper nc localhost 2181)
done
echo "Zookeeper ready!!"

# Wait brokers is UP
FOUND=''
while [[ $FOUND != "yes" ]]; do
  echo "Waiting Broker UP..."
  sleep 1
  FOUND=$(docker-compose exec mainZookeeper zookeeper-shell mainZookeeper get /brokers/ids/1 &>/dev/null && echo 'yes')
done
echo "Broker ready!!"

# Create the test-topics
docker-compose exec mainKafka kafka-topics --bootstrap-server mainKafka:9092 --topic topic-test-t1 --create --partitions 1 --replication-factor 1
docker-compose exec mainKafka kafka-topics --bootstrap-server mainKafka:9092 --topic topic-test-t2 --create --partitions 1 --replication-factor 1
docker-compose exec mainKafka kafka-topics --bootstrap-server mainKafka:9092 --topic topic-test-t3 --create --partitions 1 --replication-factor 1

#create the schemas
curl -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" --data @data/schema.avsc  http://localhost:8081/subjects/topic-test-t1-value/versions
curl -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" --data @data/schema.avsc  http://localhost:8081/subjects/topic-test-t2-value/versions
curl -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" --data @data/schema.avsc  http://localhost:8081/subjects/topic-test-t3-value/versions

HEADER="Content-Type: application/json"
DATA=$(cat data/mongosink.json)

RETCODE=1
while [ $RETCODE -ne 0 ]
do
  curl -f -X POST -H "${HEADER}" --data "${DATA}" http://localhost:8083/connectors
  RETCODE=$?
  if [ $RETCODE -ne 0 ]
  then
    echo "Failed to submit mongodb to Connect. This could be because the Connect worker is not yet started. Will retry in 10 seconds"
  fi
  #backoff
  sleep 10
done
echo "replicator configured"

# show result
docker-compose ps -a