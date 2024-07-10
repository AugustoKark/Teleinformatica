output "tf_router_ip" {
  value = openstack_networking_router_v2.tf_router.external_fixed_ip.0.ip_address
}

output "tf_bastion_fip" {
  value = openstack_networking_floatingip_v2.tf_bastion_fip.address
}

output "tf_lb_ip" {
  value = openstack_networking_floatingip_v2.tf_lb_fip.address
}


output "tf_metabase" {
  value = openstack_compute_instance_v2.tf_metabase.network.0.fixed_ip_v4
}

output "tf_db" {
  value = openstack_compute_instance_v2.tf_db.network.0.fixed_ip_v4
}

output "site_url" {
  value = "http://${openstack_networking_floatingip_v2.tf_lb_fip.address}/"
}

