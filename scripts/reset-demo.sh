#!/bin/bash
#
# SCRIPT: reset-demo.sh
#
# DESC: This script resets the DC/OS demo environment by destroying all services running
#       on the cluster and removing the service account users and secrets.
#
# AUTHOR: Greg Palmer
#

# Check if the scripts directory exists
if [ ! -d "./scripts" ]
then
    echo
    echo " Error: directory \"./scripts\" not found. Please run this script"
    echo "        from the dcos-demo-1.13 directory."
    echo
    exit 1
fi

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

# If not installed, install the enterprise CLI so we can create
# service account users and secrets
cli_security=$(dcos | grep security) #  check if the security subcommand is already installed
if [ "$cli_security" == "" ]
then
    echo
    echo " CLI package dcos-enterprise-cli not installed. Installing. "
    result=$(dcos package install dcos-enterprise-cli --yes 2>&1)

    if [[ "$result" == *"Could not access"* ]]
    then
        echo ""
        echo " ERROR: DC/OS Catalog (Universe) is unreachable. See error:"
        echo ""
        echo "$result"
        exit 1
    fi
fi

echo " Installing Kubernetes CLI  package "
dcos package install --cli kubernetes --yes > /dev/null 2>&1

# Remove the Kubernetes API Server proxies
echo
echo " Removing Kubernetes API Server proxies"
dcos marathon app remove /k8s-api-proxies/k8s-c1
dcos marathon app remove /k8s-api-proxies/k8s-c2
dcos marathon group remove  /k8s-api-proxies

# Remove Kubernetes k8s-c11 through  k8s-c5
echo
echo " Destroying Kubernetes Clusters "
dcos kubernetes cluster delete  --cluster-name=k8s-c5 --yes
sleep 2
dcos kubernetes cluster delete  --cluster-name=k8s-c4 --yes
sleep 2
dcos kubernetes cluster delete  --cluster-name=k8s-c3 --yes
sleep 2
dcos kubernetes cluster delete  --cluster-name=k8s-c2 --yes
sleep 2
dcos kubernetes cluster delete  --cluster-name=k8s-c1 --yes


sleep 60

echo
echo " Uninstalling Kubernetes Control Plane Manager package "
dcos package uninstall --app-id=kubernetes kubernetes --yes > /dev/null 2>&1
sleep 20

# Remove the secret and service account user for kubernetes clusters
echo
echo " Removing secret and service account user for MKE cluster k8s-c5"
scripts/remove-k8s-permissions.sh k8s-c5
scripts/remove-k8s-permissions.sh k8s-c4
scripts/remove-k8s-permissions.sh k8s-c3
scripts/remove-k8s-permissions.sh k8s-c2
scripts/remove-k8s-permissions.sh k8s-c1

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
echo " Removing Jupyter Notebook"
dcos package uninstall jupyterlab --yes > /dev/null 2>&1

echo
echo " Removing DC/OS Marathon-LB load balancer"
dcos package uninstall marathon-lb --app-id=loadbalancer --yes > /dev/null 2>&1

echo
echo " Removing /webapps & /mobileappsgroup"
dcos marathon group remove /webapps > /dev/null 2>&1
dcos marathon group remove /mobileapps > /dev/null 2>&1

echo
echo " Removing ~/.kube directory "
rm -rf ~/.kube > /dev/null 2>&1


