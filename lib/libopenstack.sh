#!/bin/bash

OS_TF_DIR=k8s/cluster/openstack

function os_start_cluster() {
    terraform -chdir="${OS_TF_DIR}" init
	terraform -chdir="${OS_TF_DIR}" apply -auto-approve
}

function os_get_kubeconfig() {
    local path=$1
    local context_name=$2

	eval $(terraform -chdir="${OS_TF_DIR}" output -raw get_kubeconfig) \
		| sed "s/default/$context_name/g" \
		| sed "s/127.0.0.1/$(terraform -chdir=$OS_TF_DIR output -raw ip)/g" \
		> $path
}

function os_get_cluster_address() {
	terraform -chdir="$OS_TF_DIR" output -raw ip
}

function os_stop_cluster() {
    terraform -chdir="${OS_TF_DIR}" destroy
}
