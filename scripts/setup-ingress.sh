#!/bin/bash
#
# SCRIPT: setup-ingress.sh
#

public_node_0_line=$(kubectl get node | grep kube-node-public-0)
if [[ "$public_node_0_line" == *"Ready"* ]]
then
    echo " Public Kubelet 0 is ready"
else
    echo " Pubilc Kubelet 0 is not ready, exiting."
    echo
    exit -1
fi

public_node_1_line=$(kubectl get node | grep kube-node-public-1)
if [[ "$public_node_1_line" == *"Ready"* ]]
then
    echo " Public Kubelet 1 is ready"
else
    echo " Pubilc Kubelet 1 is not ready, exiting."
    echo
    exit -1
fi

echo
echo " Deploying the Traefik Ingress Controller"
echo

cat <<EOF | kubectl create -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: traefik-ingress-controller
rules:
  - apiGroups:
      - ""
    resources:
      - services
      - endpoints
      - secrets
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - extensions
    resources:
      - ingresses
    verbs:
      - get
      - list
      - watch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: traefik-ingress-controller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: traefik-ingress-controller
subjects:
- kind: ServiceAccount
  name: traefik-ingress-controller
  namespace: kube-system
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: traefik-ingress-controller
  namespace: kube-system
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: traefik-ingress-controller
  namespace: kube-system
  labels:
    k8s-app: traefik-ingress-lb
spec:
  selector:
    matchLabels:
      k8s-app: traefik-ingress-lb
      name: traefik-ingress-lb
  template:
    metadata:
      labels:
        k8s-app: traefik-ingress-lb
        name: traefik-ingress-lb
    spec:
      serviceAccountName: traefik-ingress-controller
      terminationGracePeriodSeconds: 60
      containers:
      - image: traefik:v1.7.2
        name: traefik-ingress-lb
        ports:
        - name: http
          containerPort: 80
          hostPort: 80
        - name: admin
          containerPort: 8080
          hostPort: 8080
        securityContext:
          capabilities:
            drop:
            - all
            add:
            - NET_BIND_SERVICE
        args:
        - --api
        - --kubernetes
        - --logLevel=INFO
      nodeSelector:
        kubernetes.dcos.io/node-type: public
      tolerations:
      - key: "node-type.kubernetes.dcos.io/public"
        operator: "Exists"
        effect: "NoSchedule"
EOF

echo
echo " Checking for 2 running Traefik Ingress Controllers"
echo
traefik_check=$(kubectl -n kube-system get pods | grep traefik)
echo $traefik_check
echo

traefik_instance_count=$(echo $traefik_check | wc -l)
if [ "$traefik_instance_count" -ne 2 ]
then
    echo
    echo " We don\'t have 2 instances of the Traefik Ingress Controller running. Exiting"
    echo
    exit -1
fi

echo
echo " Launching a POD that uses the Traefik Ingress Controller"
echo

cat <<EOF | kubectl create -f -
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-world
  labels:
    app: hello-world
spec:
  replicas: 2
  selector:
    matchLabels:
      app: hello-world
  template:
    metadata:
      labels:
        app: hello-world
    spec:
      containers:
      - name: echo-server
        image: hashicorp/http-echo
        args:
        - -listen=:80
        - -text="Hello from Kubernetes!"
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: hello-world
spec:
  selector:
    app: hello-world
  ports:
    - port: 80
      targetPort: 80
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: traefik
  name: hello-world
spec:
  rules:
  - http:
      paths:
      - path: /
        backend:
          serviceName: hello-world
          servicePort: 80
EOF

