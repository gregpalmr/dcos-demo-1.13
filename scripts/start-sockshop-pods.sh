#!/bin/bash
#
# SCRIPT: start-sockshop-pods.sh
#

# Get the git up if you don't have it for the Sock Shop Kubernetes Demo
#
#git clone https://github.com/microservices-demo/microservices-demo

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
get-dcos-public-agent-ip.sh

echo
echo " Point your web browser to this URL:"
echo
echo " http://<public agent ip>:30001 "
echo

echo
echo " To destroy the sock-shop application components, run these commands:"
echo
# Destroy the demo 
#
echo "     kubectl -n sock-shop delete pods,svc,deployment --all "
echo "     kubectl delete namespace sock-shop "

# end of script

