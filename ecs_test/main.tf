resource "huaweicloud_vpc" "vpc_basic" {
  name = var.vpc_name
  cidr = var.vpc_cidr
}

resource "huaweicloud_vpc_subnet" "subnet_basic" {
  vpc_id = huaweicloud_vpc.vpc_basic.id
  name = var.subnet_name
  cidr = var.subnet_cidr
  gateway_ip = var.subnet_gateway
  dns_list = var.dns_list
}

resource "huaweicloud_networking_secgroup" "secgroup_1" {
  name        = "secgroup-basic"
  description = "basic security group"
}

# allow ping
resource "huaweicloud_networking_secgroup_rule" "allow_ping" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = huaweicloud_networking_secgroup.secgroup_1.id
}

# allow https
resource "huaweicloud_networking_secgroup_rule" "allow_https" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = huaweicloud_networking_secgroup.secgroup_1.id
}


data "huaweicloud_availability_zones" "myaz" {}

data "huaweicloud_compute_flavors" "myflavor" {
  availability_zone = data.huaweicloud_availability_zones.myaz.names[2]
  performance_type  = "normal"
#   generation = "s6"
  cpu_core_count    = 1
  memory_size       = 1
}

# data "huaweicloud_vpc_subnet" "mynet" {
#   name = var.subnet_name
# }

data "huaweicloud_images_image" "myimage" {
  name        = "Ubuntu 18.04 server 64bit"
  most_recent = true
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!@#$%*"
  
}

resource "huaweicloud_compute_instance" "basic" {
  # for_each = var.ecs_names
  name              = "terraform_ecs_test_oc"
  admin_pass        = "Oc1234@@"
  image_id          = data.huaweicloud_images_image.myimage.id
  #flavor_id         = data.huaweicloud_compute_flavors.myflavor.ids[0]
  flavor_id = "s6.small.1"
  security_groups   = ["secgroup-basic"]
  # availability_zone = each.value.availability_zones

  network {
    uuid = huaweicloud_vpc_subnet.subnet_basic.id
  }
}

