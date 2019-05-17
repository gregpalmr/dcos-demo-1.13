#!/bin/bash
#
# SCRIPT: start-proxies.sh
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

# Check if the DC/OS CLI command is installed
result=$(which dcos)
if [ "$result" == "" ]
then
    echo ""
    echo " ERROR: The DC/OS CLI command binary is not installed. Please install it. "
    echo ""
    exit 1
fi

# Check if the DC/OS CLI is correctly logged into a cluster
if [[ "$result" == *"Authentication failed"* ]]
then
    echo
    echo " ERROR: Not logged in. Please log into the DC/OS cluster with the "
    echo " command 'dcos auth login'"
    echo " Exiting."
    echo
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


echo " Installing the DC/OS CLI Kubernetes subcommand"
dcos package install --cli kubernetes --yes  > /dev/null 2>&1

echo
echo " Starting HAProxy service for the Kubernetes API server for kubernetes clusters: k8s-1 & k8s-2"
echo

sed 's/SVC_NAME/k8s-1/g' resources/haproxy-marathon.json > /tmp/haproxy.json
dcos marathon app add /tmp/haproxy.json > /dev/null 2>&1
sleep 2

sed 's/SVC_NAME/k8s-2/g' resources/haproxy2-marathon.json > /tmp/haproxy.json
dcos marathon app add /tmp/haproxy.json > /dev/null 2>&1
sleep 2

rm -f /tmp/haproxy.json

echo ' Running script: setup-kubectl.sh'
scripts/setup-kubectl.sh
echo
echo

# End of script
