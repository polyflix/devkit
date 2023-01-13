#!/bin/bash

REQUIREMENTS=( k3d helmfile helm docker )

K3D_CLUSTER_NAME=polyflix
K3D_CLUSTER_AGENTS=3

HOSTS="127.0.0.1 polyflix.local console.minio.polyflix.local kibana.polyflix.local minio keycloak"

function clean_exit() {
  echo "$@"
  exit 1
}

function check_requirements() {
  for requirement in "${REQUIREMENTS[@]}"; do
    which "$requirement" > /dev/null || clean_exit "[ERROR] Missing requirement. Please install '$requirement' and try re-run the script."
  done
}

function start_k3d() {
  k3d cluster create "${K3D_CLUSTER_NAME}" \
    --port "8080:80@loadbalancer" \
    --agents "${K3D_CLUSTER_AGENTS}" \
    --k3s-arg "--disable=traefik@server:*" \
    --k3s-arg '--kubelet-arg=eviction-hard=imagefs.available<1%,nodefs.available<1%@agent:*' \
    --k3s-arg '--kubelet-arg=eviction-minimum-reclaim=imagefs.available=1%,nodefs.available=1%@agent:*'
}

function stop_k3d() {
  k3d cluster delete "${K3D_CLUSTER_NAME}"
}

function inject_hosts() {
  echo "[INFO] Injecting hosts into /etc/hosts"
  echo "${HOSTS}" | sudo tee -a /etc/hosts
}

function clean_hosts() {
  echo "[INFO] Cleaning up in /etc/hosts"
  sudo sed -i '' 's/127.0.0.1 polyflix.local console.minio.polyflix.local kibana.polyflix.local minio keycloak//g' /etc/hosts
}

function install() {
  # Install Elastic Cloud Kit operator
  kubectl create -f https://download.elastic.co/downloads/eck/2.6.1/crds.yaml
  kubectl apply -f https://download.elastic.co/downloads/eck/2.6.1/operator.yaml
  kubectl apply -f ./manifests/eck
  kubectl apply -f ./manifests

  kubectl create configmap keycloak-realm --from-file=realm.json=config/keycloak-realm.json

  helmfile apply
}

function start() {
  check_requirements
  start_k3d
  install
  inject_hosts
}

function stop() {
  stop_k3d
  clean_hosts
}

$1