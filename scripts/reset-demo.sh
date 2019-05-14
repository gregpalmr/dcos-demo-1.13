#!/bin/bash
#
# SCRIPT: reset-demo.sh
#
# DESC: This script resets the DC/OS demo environment by destroying all services running
#       on the cluster and removing the service account users and secrets.
#
# AUTHOR: Greg Palmer
#

# Check if the DC/OS CLI command is installed
result=$(which dcos)
if [ "$result" == "" ]
then
    echo ""
    echo " ERROR: The DC/OS CLI command binary is not installed. Please install it. "
    echo ""
    exit 1
fi

# Check if the DC/OS CLI command is working against a working cluster
result=$(dcos node 2>&1)

if [[ "$result" == *"is unreachable"* ]]
then
    echo ""
    echo " ERROR: DC/OS Master Node is unreachable. Is the DC/OS CLI configured correctly"
    echo ""
    echo "        Run:   dcos cluster setup <master node ip>"
    exit 1
fi

echo

# Install the enterprise CLI so we can create service account users and secrets
echo " Installing dcos-enterprise-cli package "
dcos package install --cli dcos-enterprise-cli --yes > /dev/null 2>&1

echo " Installing Kubernetes CLI  package "
dcos package install --cli kubernetes --yes > /dev/null 2>&1

# Remove the Kubernetes API Server proxies
echo
echo " Removing Kubernetes API Server proxies"
dcos marathon app remove /k8s-api-proxies/k8s-1
dcos marathon app remove /k8s-api-proxies/k8s-2
dcos marathon group remove  /k8s-api-proxies

# Remove Kubernetes k8s-1 and k8s-2
echo
echo " Destroying Kubernetes Clusters "
dcos kubernetes cluster delete  --cluster-name=k8s-5 --yes
sleep 2
dcos kubernetes cluster delete  --cluster-name=k8s-4 --yes
sleep 2
dcos kubernetes cluster delete  --cluster-name=k8s-3 --yes
sleep 2
dcos kubernetes cluster delete  --cluster-name=k8s-2 --yes
sleep 2
dcos kubernetes cluster delete  --cluster-name=k8s-1 --yes


sleep 60

echo
echo " Uninstalling Kubernetes Control Plane Manager package "
dcos package uninstall --app-id=kubernetes kubernetes --yes > /dev/null 2>&1
sleep 20

# Remove the secret and service account user for kubernetes cluster1
echo
echo " Removing secret and service account user for MKE cluster k8s-5"
scripts/remove-k8s-permissions.sh k8s-5
scripts/remove-k8s-permissions.sh k8s-4
scripts/remove-k8s-permissions.sh k8s-3
scripts/remove-k8s-permissions.sh k8s-2
scripts/remove-k8s-permissions.sh k8s-1

echo
echo " Removing the Kubenetes Control Plane Manager service account user"
echo
dcos security secrets delete kubernetes/sa > /dev/null 2>&1
dcos security org service-accounts delete kubernetes > /dev/null 2>&1

echo
echo " Removing Cassandra"
dcos package uninstall cassandra --yes > /dev/null 2>&1

echo
echo " Removing Kafka"
dcos package uninstall kafka --yes > /dev/null 2>&1

echo
echo " Removing Spark"
dcos package uninstall spark --yes > /dev/null 2>&1

echo
echo " Removing hdfs"
dcos package uninstall hdfs --yes > /dev/null 2>&1

echo
echo " Removing DC/OS Monitoring"
dcos package uninstall beta-dcos-monitoring --yes > /dev/null 2>&1

echo
echo " Removing ~/.kube directory "
rm -rf ~/.kube > /dev/null 2>&1


