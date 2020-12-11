#!/bin/bash -x

BLUE="false"
GREEN="false"

BLUE_IP=192.168.4.4
GREEN_IP=192.168.4.5

# Function that writes out Yaml for sample app
function writeYaml() {
  COLOR=$1
  cat <<EOF > nginx-$COLOR.yaml 
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-$COLOR-dep
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx-$COLOR
  template:
    metadata:
      labels:
        app: nginx-$COLOR
    spec:
      nodeSelector:
        nodepoolcolor: $COLOR
        nodepoolmode: user
      containers:
      - image: nginxdemos/hello
        name: nginx-$COLOR
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "350m"
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-$COLOR-svc
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: nginx-$COLOR
  type: ClusterIP
---
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: nginx-$COLOR-ing
  annotations:
    kubernetes.io/ingress.class: $COLOR
    nginx.ingress.kubernetes.io/ingress.class: $COLOR
    nginx.ingress.kubernetes.io/use-regex: "true"
    nginx.ingress.kubernetes.io/rewrite-target: /$1
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  rules:
  - http:
       paths:
       - backend:
           serviceName: nginx-$COLOR-svc
           servicePort: 80
         path: /(/|$)(.*)
       - backend:
           serviceName: nginx-$COLOR-svc
           servicePort: 80
         path: /nginx(/|$)(.*)
EOF

}

#Function for install nginx for each color nodepool
#This will be called based on whether there a any nodes
#that can be scheduled on for that color
installNginx() {
  COLOR=$1
  IP_ADDRESS=$2
  # Use Helm to deploy an NGINX ingress controller
  helm install ingress-$COLOR ingress-nginx/ingress-nginx --wait -f - \
    --namespace nginx \
    --set controller.ingressClass=$COLOR \
    --set controller.replicaCount=2 \
    --set controller.nodeSelector."beta\.kubernetes\.io/os"=linux \
    --set defaultBackend.nodeSelector."beta\.kubernetes\.io/os"=linux \
    --set controller.service.loadBalancerIP=$IP_ADDRESS \
    --set controller.nodeSelector.nodepoolcolor=$COLOR << EOF
controller:
  service:
    annotations:
      service.beta.kubernetes.io/azure-load-balancer-internal: "true"
      service.beta.kubernetes.io/azure-load-balancer-internal-subnet: "clusteringressservices"
EOF

  sleep 5; while echo && kubectl get service -n nginx --no-headers | grep $COLOR | grep -v -E "($IP_ADDRESS|<none>)"; do sleep 5; done
}

#MAIN PROGRAM
##############

# These are the blue nodes that can be scheduled
kubectl get nodes -l nodepoolcolor=blue --no-headers | grep -v SchedulingDisabled 
if [ $? == 0 ]; then
  BLUE="true"
fi

# These are the green nodes that can be scheduled
kubectl get nodes -l nodepoolcolor=green --no-headers | grep -v SchedulingDisabled 
if [ $? == 0 ]; then
  GREEN="true"
fi

echo "GREEN POOL is $GREEN"
echo "BLUE POOL is $BLUE"

# Create a namespace for your ingress resources
kubectl create namespace nginx

# Add the ingress-nginx repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx 

if [ $BLUE = "true" ]; then
  installNginx blue $BLUE_IP
  writeYaml blue
  kubectl apply -f nginx-blue.yaml
fi

if [ $GREEN = "true" ]; then
  installNginx green $GREEN_IP
  writeYaml green
  kubectl apply -f nginx-green.yaml
fi


