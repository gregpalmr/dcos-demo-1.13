#!/bin/bash
#
# SCRIPT: setup-kubectl.sh
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

# Wait for the k8s-1 cluster deploy to complete
echo
echo " Waiting for MKE cluster named k8s-1 to deploy completely using the command:"
echo
echo "    $ dcos kubernetes manager plan status deploy --name=k8s-1 | grep -v COMPLETE"
echo
while true
do
    plan_complete=$(dcos kubernetes manager plan status deploy --name=k8s-1 | grep -v COMPLETE)
    if [ "$plan_complete" != "" ]
    then
        echo -n "."
        sleep 3
    else
        break
    fi
done

# Check to see if the first api-server proxy is running
echo
echo " Waiting for Kubernetes API Server proxies to start"
while true
do
    dcos task k8s-api-proxies_k8s-1 > /dev/null 2>&1
    if [ "$?" != 0 ]
    then
        echo -n "."
    else
        break
    fi
done

echo
echo " Getting IP Addresses of the DC/OS agents running the HAProxy services "
echo "     NOTE: You must run ssh-add to add your DC/OS cluster's SSH key to your cache for this to work"
echo

HAPROXY1_PUB_IP=$(priv_ip=$(dcos task k8s-api-proxies_k8s-1 | grep -v HOST | awk '{print $2}') && dcos node ssh --option StrictHostKeyChecking=no --option LogLevel=quiet --master-proxy --private-ip=$priv_ip --user=centos "curl http://169.254.169.254/latest/meta-data/public-ipv4");

HAPROXY2_PUB_IP=$(priv_ip=$(dcos task k8s-api-proxies_k8s-2 | grep -v HOST | awk '{print $2}') && dcos node ssh --option StrictHostKeyChecking=no --option LogLevel=quiet --master-proxy --private-ip=$priv_ip --user=centos "curl http://169.254.169.254/latest/meta-data/public-ipv4"); 

echo
echo " Kubernetes API Server Proxy 1: $HAPROXY1_PUB_IP  - http://${HAPROXY1_PUB_IP}:9091/haproxy?stats "
echo
echo " Kubernetes API Server Proxy 2: $HAPROXY2_PUB_IP  - http://${HAPROXY2_PUB_IP}:9092/haproxy?stats "
echo

# Setup kubectl to use the proxies to the api-servers
echo
echo " Setting up kubectl to use the proxies "

rm -rf ~/.kube.backup > /dev/null 2>&1
mv ~/.kube ~/.kube.backup > /dev/null 2>&1

dcos kubernetes cluster kubeconfig \
    --insecure-skip-tls-verify \
    --context-name=k8s-2 \
    --cluster-name=k8s-2 \
    --apiserver-url=https://${HAPROXY2_PUB_IP}:6444

dcos kubernetes cluster kubeconfig \
    --insecure-skip-tls-verify \
    --context-name=k8s-1 \
    --cluster-name=k8s-1 \
    --apiserver-url=https://${HAPROXY1_PUB_IP}:6443

echo
echo " Starting Kubernetes Web Console proxy with command:"
echo "   kubectl proxy > /dev/null &"

# Kill any old "kubectl proxy" commands running
killall kubectl > /dev/null 2>&1
kubectl proxy > /dev/null &
sleep 3
open -a "Google Chrome" http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/

echo
echo " Use the following kubeconfig tokens to access the K8s Web console:"
echo
echo
cat ~/.kube/config | grep token
echo
echo

echo
echo " kubectl setup for 2 Kubernetes clusters. To switch contexts, use these commands:"
echo
echo " kubectl config get-contexts"
echo " kubectl config use-context k8s-2"
echo " kubectl config use-context k8s-1"
echo

# End of script
