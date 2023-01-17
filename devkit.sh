#!/bin/bash

K8S_CONTEXT_NAME="polyflix-devkit"
CLUSTER_PROVIDER=""

source lib/libk3d.sh
source lib/libopenstack.sh
source lib/libhelper.sh

function clean_exit() {
  echo "$@"
  exit 1
}

function check_requirements() {
  for requirement in "${REQUIREMENTS[@]}"; do
    which "$requirement" > /dev/null || clean_exit "[ERROR] Missing requirement. Please install '$requirement' and try re-run the script."
  done
}

function get_hosts() {
  local ip=${1:-127.0.0.1}
  echo "$ip polyflix.local console.minio.polyflix.local kibana.polyflix.local minio keycloak"
}

function install() {
  local kubeconfig="$(pwd)/outputs/k8s.yml"
  local kubectl_args="--context=$K8S_CONTEXT_NAME --kubeconfig=$kubeconfig"
  
  kubectl $kubectl_args create configmap provisioning --from-file=provisioning.sh=./scripts/provisioning.sh || true
  kubectl $kubectl_args create configmap keycloak-realm --from-file=realm.json=./config/keycloak-realm.json || true

  # Install Elastic Cloud Kit operator
  kubectl $kubectl_args create -f https://download.elastic.co/downloads/eck/2.6.1/crds.yaml || true
  kubectl $kubectl_args apply -f https://download.elastic.co/downloads/eck/2.6.1/operator.yaml || true
  kubectl $kubectl_args apply -f ./k8s/manifests/eck || true
  kubectl $kubectl_args apply -f ./k8s/manifests/postgres || true

  # We need to instal Polyflix before running the provisioning step
  KUBECONFIG=$kubeconfig helmfile --kube-context="$K8S_CONTEXT_NAME" --file ./k8s/helmfile.yaml apply

  kubectl $kubectl_args apply -f ./k8s/manifests/polyflix
}

function start() {
  check_requirements
  # start_k3d
  install
  inject_hosts
}

function stop() {
  stop_k3d
  clean_hosts
}

function sub_default(){
  local progname=`basename "$0"`
  echo "This script will allow you to manage Polyflix development environment."
  echo "Usage: $progname <command>"
  echo "Commands:"
  echo "    start <provider> Start a new devkit environment on the given provider."
  print_generic_options
}

sub_start() {
  local ip=""
   if [[ "$#" == 0 ]]; then
      sub_default
      exit 1
    fi

    mkdir -p outputs

    CLUSTER_PROVIDER=${1:-}
    case $CLUSTER_PROVIDER in
      openstack)
        os_start_cluster
        os_get_kubeconfig outputs/k8s.yml "$K8S_CONTEXT_NAME"
        ip=$(os_get_cluster_address)
      ;;
      local)
        k3d_start_cluster || true
        k3d_get_kubeconfig outputs/k8s.yml "$K8S_CONTEXT_NAME"
        ip="127.0.0.1"
      ;;
      *)
        echo "[ERROR]: Invalid provider given '${CLUSTER_PROVIDER}'. Valid providers are: local, openstack"
        exit 1
      ;;
    esac

    install
    
    echo $(get_hosts "$ip") | sudo tee -a /etc/hosts
}

sub_stop() {
  local ip=""
  if [[ "$#" == 0 ]]; then
    sub_default
    exit 1
  fi

  CLUSTER_PROVIDER=${1:-}
  case $CLUSTER_PROVIDER in
    openstack)
      ip=$(os_get_cluster_address)
      os_stop_cluster
    ;;
    local)
      ip="127.0.0.1"
      k3d_stop_cluster
    ;;
    *)
      echo "[ERROR]: Invalid provider given '${CLUSTER_PROVIDER}'. Valid providers are: local, openstack"
      exit 1
    ;;
  esac

  sudo sed -i '' "s/$(get_hosts $ip)//g" /etc/hosts
  rm -rf outputs
}

parse_and_execute $@
