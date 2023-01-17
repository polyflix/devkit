output "ip" {
  value = openstack_networking_floatingip_v2.this.address
}

output "get_kubeconfig" {
  value = "sleep 10 && ssh debian@${openstack_networking_floatingip_v2.this.address} 'sudo cat /etc/rancher/k3s/k3s.yaml'"
}
