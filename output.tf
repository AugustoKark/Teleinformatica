output "tf_router_ip" {
  value = openstack_networking_router_v2.tf_router.external_fixed_ip.0.ip_address
}

output "tf_bastion_fip" {
  value = openstack_networking_floatingip_v2.tf_bastion_fip.address
}

output "tf_lb_ip" {
  value = openstack_networking_floatingip_v2.tf_lb_fip.address
}

output "site_url" {
  value = "http://${openstack_networking_floatingip_v2.tf_lb_fip.address}/blog/"
}