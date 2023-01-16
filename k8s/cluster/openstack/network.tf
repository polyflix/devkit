data "openstack_networking_network_v2" "public" {
  name     = "public"
  external = true
}

resource "openstack_networking_network_v2" "this" {
  name           = local.environment
  admin_state_up = true
}

resource "openstack_networking_subnet_v2" "this" {
  network_id      = openstack_networking_network_v2.this.id
  name            = local.environment
  cidr            = "10.1.0.0/24"
  dns_nameservers = ["1.1.1.1"]
  ip_version      = 4
}

resource "openstack_networking_router_v2" "this" {
  name                = local.environment
  external_network_id = data.openstack_networking_network_v2.public.id
  admin_state_up      = true
}

resource "openstack_networking_router_interface_v2" "this" {
  router_id = openstack_networking_router_v2.this.id
  subnet_id = openstack_networking_subnet_v2.this.id
}

resource "openstack_networking_floatingip_v2" "this" {
  pool = data.openstack_networking_network_v2.public.name
}
