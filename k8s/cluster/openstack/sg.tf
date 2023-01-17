resource "openstack_networking_secgroup_v2" "this" {
  name = local.environment
}

resource "openstack_networking_secgroup_rule_v2" "ingress" {
  for_each          = { for port in [22, 80, 443, 6443] : port => port }
  security_group_id = openstack_networking_secgroup_v2.this.id
  direction         = "ingress"
  protocol          = "tcp"
  ethertype         = "IPv4"
  port_range_min    = each.key
  port_range_max    = each.key
}
