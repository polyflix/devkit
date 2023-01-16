#!/bin/bash

function k3d_start_cluster() {
    k3d cluster create polyflix \
        --port "80:80@loadbalancer" \
        --agents 3 \
        --k3s-arg "--disable=traefik@server:*" \
        --k3s-arg '--kubelet-arg=eviction-hard=imagefs.available<1%,nodefs.available<1%@agent:*' \
        --k3s-arg '--kubelet-arg=eviction-minimum-reclaim=imagefs.available=1%,nodefs.available=1%@agent:*'
}

function k3d_get_kubeconfig() {
    local path=$1
    local context_name=$2

    k3d kubeconfig get polyflix \
        | sed "s/default/$context_name/g" \
        > $path
}

function k3d_stop_cluster() {
    k3d cluster delete polyflix
}
