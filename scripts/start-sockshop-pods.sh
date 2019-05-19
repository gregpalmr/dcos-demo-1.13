#!/bin/bash
#
# SCRIPT: start-sockshop-pods.sh
#

# Get the git up if you don't have it for the Sock Shop Kubernetes Demo
#
#git clone https://github.com/microservices-demo/microservices-demo

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
echo " Creating namespace: shock-shop"
kubectl create namespace sock-shop
kubectl apply -f resources/sock-shop-demo.yaml

echo
echo " Showing sock-shop pod info for namespace shock-shop"
echo " Using command: kubectl -n sock-shop get pods"
echo
sleep 2
kubectl -n sock-shop get pods
echo
sleep 3
kubectl -n sock-shop get pods

echo
echo " Note, the sock-shop app uses nodeport 30001"
# nodeport is on 30001

echo
echo " Getting public ip addresses of your public agent nodes"
echo

HAPROXY1_PUB_IP=$(priv_ip=$(dcos task k8s-api-proxies_k8s-1 | grep -v HOST | awk '{print $2}') && dcos node ssh --option StrictHostKeyChecking=no --option LogLevel=quiet --master-proxy --private-ip=$priv_ip --user=centos "curl http://169.254.169.254/latest/meta-data/public-ipv4");

echo 
echo " Opening a Google Chrome Tab for the Sock Shop Demo web page"
sleep 3
open -a "Google Chrome" http://${HAPROXY1_PUB_IP}:30001

echo
echo "OR,  To view the sock shop web page, point your web browser to this URL:"
echo
echo "     http://${HAPROXY1_PUB_IP}:30001 "
echo

echo
echo " To destroy the sock-shop application components, run these commands:"
echo

# Destroy the demo 
#
echo "     kubectl -n sock-shop get pods "
echo "     kubectl -n sock-shop delete pods,svc,deployment --all "
echo "     kubectl delete namespace sock-shop "

# end of script

