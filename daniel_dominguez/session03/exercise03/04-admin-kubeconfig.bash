﻿#!/bin/bash

source ./common.bash

#
# Kubernetes Control Plane: API Server
#
# At the end of this script you will have running API Server
#

echo "Creating kubernetes admin user kubeconfig"

mkdir -p "$ADMIN_CERT_DIR"

#
# Create admin server certificate
#
export ADMIN_CSR_PATH=/tmp/admin.csr

## Private key
openssl genrsa -out "$ADMIN_KEY_PATH" 2048

## Certificate sign request
openssl req -new -key "$ADMIN_KEY_PATH" -out "$ADMIN_CSR_PATH" -subj "/CN=kubernetes/O=system:masters"

## Copy the request to the server (NOT THE PROPER WAY)
scp $ADMIN_CSR_PATH $UBUNTU_USER@${CONTROLLER_PUBLIC_IPS[0]}:/tmp/

#
# This part is done on the server side
#

ssh $UBUNTU_USER@${CONTROLLER_PUBLIC_IPS[0]} "sudo openssl x509 -req -in /tmp/admin.csr -CA $KUBERNETES_CA_CERT_PATH -CAkey $KUBERNETES_CA_KEY_PATH -CAcreateserial -out /tmp/admin.crt  -days 500"


#
# This part is done again on the client side
#

export ADMIN_CSR_IN_PATH=/tmp/admin.csr
export ADMIN_CERT_OUT_PATH=/tmp/admin.crt

# Download the generated certificate (NOT THE PROPER WAY)
scp $UBUNTU_USER@${CONTROLLER_PUBLIC_IPS[0]}:$ADMIN_CERT_OUT_PATH "$ADMIN_CERT_PATH"
scp $UBUNTU_USER@${CONTROLLER_PUBLIC_IPS[0]}:$KUBERNETES_CA_CERT_PATH "$ADMIN_CLUSTER_CA_PATH"

# Add new kubectl context

kubectl config set-cluster k8s-training --certificate-authority=$ADMIN_CLUSTER_CA_PATH --embed-certs=true --server=https://${CONTROLLER_PUBLIC_IPS[0]}:6443
kubectl config set-credentials k8s-training-admin --client-certificate=$ADMIN_CERT_PATH --client-key=$ADMIN_KEY_PATH --embed-certs=true
kubectl config set-context k8s-training-admin --cluster=k8s-training --user=k8s-training-admin

# Set new context
kubectl config use-context k8s-training-admin

# Create a deployment
kubectl run --image=bitnami/nginx nginx-test --replicas=3 
# Create a service
kubectl expose deployments nginx-test --port=8080 --type=NodePort

echo "End of admin kubeconfig step"
