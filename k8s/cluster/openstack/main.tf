locals {
  environment = "polyflix-development"
}

resource "openstack_compute_keypair_v2" "this" {
  name       = local.environment
  public_key = file(var.pub_ssh_key)
}

resource "openstack_compute_instance_v2" "this" {
  name            = local.environment
  security_groups = [openstack_networking_secgroup_v2.this.name]
  key_pair        = openstack_compute_keypair_v2.this.name
  flavor_name     = "m1.xlarge"
  image_name      = "debian-11-genericcloud-1"
  user_data       = <<EOF
#!/bin/bash
curl -sfL https://get.k3s.io | sh -s - server --disable traefik --tls-san "${openstack_networking_floatingip_v2.this.address}"
  EOF
  network {
    name = openstack_networking_network_v2.this.name
  }
}

resource "openstack_compute_floatingip_associate_v2" "this" {
  floating_ip = openstack_networking_floatingip_v2.this.address
  instance_id = openstack_compute_instance_v2.this.id
}
