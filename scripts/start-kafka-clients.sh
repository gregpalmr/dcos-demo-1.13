#!/bin/bash
#
# SCRIPT: start-kafka-clients.sh
#

# Check if the resources directory exists
if [ ! -d "./resources" ]
then
    echo
    echo " Error: directory \"./resources\" not found. Please run this script"
    echo "        from the dcos-demo-1.13 directory."
    echo
    exit 1
fi

echo
echo " #############################################"
echo " ### Starting Kafka Producer and Consumer  ###"
echo " #############################################"
echo
echo
echo " Waiting for Kafka service to start. "
while true
do
    task_status=$(dcos task |grep 'kafka-0-broker ' | awk '{print $4}')

    if [ "$task_status" != "R" ]
    then
        printf "."
    else
        echo " Kafka service is running."
        break
    fi
    sleep 10
done

dcos kafka topic create topic1 --partitions=3 --replication=3

sleep 2

dcos marathon app add resources/kafka-consumer.json

sleep 10

dcos kafka topic producer_test topic1 100

