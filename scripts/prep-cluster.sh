#!/bin/bash
#
# SCRIPT: prep-demo.sh
#
# DESC: This script creates the service account users for the MKE kubernetes clusters and
#       it launches 4 MKE clusters of different versions.
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

# Check if master node URL is https and not http
result=$(dcos config show core.dcos_url)

if [[ "$result" == *"http://"* ]]
then
    echo
    echo " ERROR: Your DC/OS CLI command is NOT using HTTPS. Please re-run the 'dcos cluster setup' command like this:"
    echo
    echo "        dcos cluster setup https://<master node ip addr>"
    echo
    exit 1
fi

#echo
#echo " Checking for license key  file in ~/scripts/license.txt"
#if [ -f ~/scripts/license.txt ]
#then
#    echo " Found license key file"
#else
#    echo
#    echo " ERROR: Could not find the Ent. DC/OS license key file: ~/scripts/license.txt"
#    echo ""
#    echo "        Please download the license key file and place it there."
#    exit 1
#
#fi

# Install the enterprise CLI so we can create service account users and secrets
echo
echo " Installing dcos-enterprise-cli package "
result=$(dcos package install dcos-enterprise-cli --yes 2>&1)

if [[ "$result" == *"Could not access"* ]]
then
    echo ""
    echo " ERROR: DC/OS Catalog (Universe) is unreachable. See error:"
    echo ""
    echo "$result"
    exit 1
fi

#echo
#echo " Getting current license status"
#dcos license status
#
#echo
#echo " Updating the license key with ~/scripts/license.txt"
#dcos license renew  ~/scripts/license.txt
#dcos license status

# Create the service account user for kubernetes control plane manager
echo
echo " Creating SSL Cert and Service Account User for kubernetes control plane manager"
scripts/create-k8s-permissions.sh kubernetes

# Create the service account user for kubernetes cluster: k8s-1
echo
echo " Creating SSL Cert and Service Account User for: k8s-1, k8s-2, k8s-3, k8s-4"
scripts/create-k8s-permissions.sh k8s-1
scripts/create-k8s-permissions.sh k8s-2
scripts/create-k8s-permissions.sh k8s-3
scripts/create-k8s-permissions.sh k8s-4
scripts/create-k8s-permissions.sh k8s-5  # This one will not be started in advance

# Launching demo kubernetes clusters
echo
echo " Launching demo kubernetes clusters: k8s-1, k8s-2, k8s-3, k8s-4"
echo

# First, start the kubernetes control plan manager
echo " Launching the MKE kubernetes control plane manager"
dcos package install --yes kubernetes --options=resources/package-kubernetes.json > /dev/null 2>&1

sleep 5

# Wait for the control plane manager to be up and responsive
echo
echo " Waiting for the MKE control plane manager to start"
while true
do
    dcos kubernetes cluster list > /dev/null 2>&1
    if [ "$?" == 0 ]
    then
        break 
    fi
    echo -n "."
    sleep 3
done

# Then start 4 actual kubernetes clusters

# Make this one an HA k8s cluster with the older k8s release (so it can be upgraded later)
echo " Launching HA kubernetes cluster: k8s-1"
sed 's/SVC_NAME/k8s-1/g' resources/package-kubernetes-cluster-ha.json > /tmp/k8s-options.json
dcos kubernetes cluster create --options=/tmp/k8s-options.json --yes --package-version="2.2.2-1.13.5" > /dev/null 2>&1
sleep 2

# Make the rest non-HA k8s clusters with various releases
echo " Launching kubernetes cluster: k8s-2"
sed 's/SVC_NAME/k8s-2/g' resources/package-kubernetes-cluster.json > /tmp/k8s-options.json
dcos kubernetes cluster create --options=/tmp/k8s-options.json --yes > /dev/null 2>&1
sleep 2

echo " Launching kubernetes cluster: k8s-3"eval $(maws login 110465657741_Mesosphere-PowerUser)
sed 's/SVC_NAME/k8s-3/g' resources/package-kubernetes-cluster.json > /tmp/k8s-options.json
dcos kubernetes cluster create --options=/tmp/k8s-options.json --yes --package-version="2.1.1-1.12.5" > /dev/null 2>&1
sleep 2

echo " Launching kubernetes cluster: k8s-4"
sed 's/SVC_NAME/k8s-4/g' resources/package-kubernetes-cluster.json > /tmp/k8s-options.json
dcos kubernetes cluster create --options=/tmp/k8s-options.json --yes --package-version="2.2.2-1.13.5" > /dev/null 2>&1
sleep 2

rm -f /tmp/k8s-options.json

# Start the proxies for the api servers
scripts/start-proxies.sh

echo " Launching Kafka package"
dcos package install --yes kafka > /dev/null 2>&1

echo " Launching Spark package"
dcos package install --yes spark > /dev/null 2>&1

echo
echo " Launching Kubernetes Microservices Demo App: SockShop"
scripts/start-sockshop-pods.sh

# end of script
