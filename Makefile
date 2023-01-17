K8S_ROOT_DIR=k8s
K8S_CONTEXT_NAME=polyflix-devkit
OUTPUTS_DIR=outputs

.PHONY: start/cluster/k3d
start/cluster/k3d:
	k3d cluster create $(K8S_CONTEXT_NAME) \
		--port "80:80@loadbalancer" \
		--agents 3 \
		--k3s-arg "--disable=traefik@server:*" \
		--k3s-arg '--kubelet-arg=eviction-hard=imagefs.available<1%,nodefs.available<1%@agent:*' \
		--k3s-arg '--kubelet-arg=eviction-minimum-reclaim=imagefs.available=1%,nodefs.available=1%@agent:*'

.PHONY: start/cluster/openstack
start/cluster/openstack:
	terraform -chdir=$(K8S_ROOT_DIR)/cluster/openstack init
	terraform -chdir=$(K8S_ROOT_DIR)/cluster/openstack apply -auto-approve
	mkdir -p $(OUTPUTS_DIR)
	eval $(shell terraform -chdir=$(K8S_ROOT_DIR)/cluster/openstack output -raw get_kubeconfig) \
		| sed 's/default/$(K8S_CONTEXT_NAME)/g' \
		| sed 's/127.0.0.1/$(shell terraform -chdir=$(K8S_ROOT_DIR)/cluster/openstack output -raw ip)/g' \
		> $(OUTPUTS_DIR)/k3s.yml

.PHONY: stop/cluster/openstack
stop/cluster/openstack:
	rm -f $(OUTPUTS_DIR)
	terraform -chdir=$(K8S_ROOT_DIR)/cluster/openstack destroy

install/requirements:
	# Install Elastic Cloud Kit operator
  	kubectl create -f https://download.elastic.co/downloads/eck/2.6.1/crds.yaml
  	kubectl apply -f https://download.elastic.co/downloads/eck/2.6.1/operator.yaml
  	kubectl apply -f ./manifests/eck
  	kubectl apply -f ./manifests

  	kubectl create configmap keycloak-realm --from-file=realm.json=config/keycloak-realm.json

  	helmfile apply

test:
	kubectl delete configmap/provisioning job/provisioning --ignore-not-found
	kubectl create configmap provisioning --from-file=provisioning.sh=./provisioning.sh
	kubectl apply -f manifests/provisioning.yaml 
