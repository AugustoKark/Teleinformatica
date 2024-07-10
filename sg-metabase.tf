resource "openstack_compute_secgroup_v2" "tf_sg_metabase" {
  name        = "tf_sg_metabase"
  description = "tf_sg_metabase"

  rule {
    from_group_id = openstack_compute_secgroup_v2.tf_sg_bastion.id
    from_port     = -1
    to_port       = -1
    ip_protocol   = "icmp"
  }
  rule {
    from_group_id = openstack_compute_secgroup_v2.tf_sg_bastion.id
    from_port     = 22
    to_port       = 22
    ip_protocol   = "tcp"
  }
  rule {
    from_group_id = openstack_compute_secgroup_v2.tf_sg_lb.id
    from_port     = 3000
    to_port       = 3000
    ip_protocol   = "tcp"
  }
}