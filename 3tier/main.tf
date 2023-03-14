data "huaweicloud_availability_zones" "myaz" {}

# Create DEMO VPC
resource "huaweicloud_vpc" "vpc_basic" {
  name = "OC_TERRAFORM_DEMO_BASIC_VPC"
  cidr = "10.0.0.0/16"
}

# Create Web Public Subnet
resource "huaweicloud_vpc_subnet" "web_subnet_1" {
  vpc_id = huaweicloud_vpc.vpc_basic.id
  name = "OC_TERRAFORM_WEB_SUBNET_1"
  cidr = "10.0.1.0/24"
  gateway_ip = "10.0.1.1"

}


resource "huaweicloud_vpc_subnet" "web_subnet_2" {
  vpc_id = huaweicloud_vpc.vpc_basic.id
  name = "OC_TERRAFORM_WEB_SUBNET_2"
  cidr = "10.0.2.0/24"
  gateway_ip = "10.0.2.1"

}


# Create Application Public Subnet
resource "huaweicloud_vpc_subnet" "application_subnet_1" {
  vpc_id = huaweicloud_vpc.vpc_basic.id
  name = "OC_TERRAFORM_APPLICATION_SUBNET_1"
  cidr = "10.0.11.0/24"
  gateway_ip = "10.0.11.1"
}


resource "huaweicloud_vpc_subnet" "application_subnet_2" {
  vpc_id = huaweicloud_vpc.vpc_basic.id
  name = "OC_TERRAFORM_APPLICATION_SUBNET_2"
  cidr = "10.0.12.0/24"
  gateway_ip = "10.0.12.1"
}

# Create Database Private Subnet
resource "huaweicloud_vpc_subnet" "database_subnet_1" {
  vpc_id = huaweicloud_vpc.vpc_basic.id
  name = "OC_TERRAFORM_DATABASE_SUBNET_1"
  cidr = "10.0.21.0/24"
  gateway_ip = "10.0.21.1"
}


resource "huaweicloud_vpc_subnet" "database_subnet_2" {
  vpc_id = huaweicloud_vpc.vpc_basic.id
  name = "OC_TERRAFORM_DATABASE_SUBNET_2"
  cidr = "10.0.22.0/24"
  gateway_ip = "10.0.22.1"
}


# Create NAT GATEWAY (SNAT) for public subnet
# 1: Small type, which supports up to 10,000 SNAT connections.
# 2: Medium type, which supports up to 50,000 SNAT connections.
# 3: Large type, which supports up to 200,000 SNAT connections.
# 4: Extra-large type, which supports up to 1,000,000 SNAT connections.
resource "huaweicloud_nat_gateway" "nat_gateway_public" {
  name        = "OC_DEMO_NAT_GATEWAY"
  description = "test for OC terraform"
  spec        = "3"
  vpc_id      = huaweicloud_vpc.vpc_basic.id
  subnet_id   = huaweicloud_vpc_subnet.web_subnet_1.id
}

# Create EIP for NAT GATEWAY
resource "huaweicloud_vpc_bandwidth" "demo_snat_eip" {
  name = "demo_snat_eip"
  size = 5
}

resource "huaweicloud_vpc_eip" "shared" {
  publicip {
    type = "5_bgp"
  }

  bandwidth {
    share_type = "WHOLE"
    id         = huaweicloud_vpc_bandwidth.demo_snat_eip.id
  }
}

# snat rule web_subnet_1
resource "huaweicloud_nat_snat_rule" "snat_web_subnet_1" {
  nat_gateway_id = huaweicloud_nat_gateway.nat_gateway_public.id
  depends_on = [
    huaweicloud_vpc_bandwidth.demo_snat_eip
  ]
  floating_ip_id = huaweicloud_vpc_eip.shared.id
  subnet_id      = huaweicloud_vpc_subnet.web_subnet_1.id
}
# snat rule web_subnet_2
resource "huaweicloud_nat_snat_rule" "snat_web_subnet_2" {
  nat_gateway_id = huaweicloud_nat_gateway.nat_gateway_public.id
  depends_on = [
    huaweicloud_vpc_bandwidth.demo_snat_eip
  ]
  floating_ip_id = huaweicloud_vpc_eip.shared.id
  subnet_id      = huaweicloud_vpc_subnet.web_subnet_2.id
}



# create basic security group
resource "huaweicloud_networking_secgroup" "secgroup_oc" {
  name        = "Secgroup-Basic-OC"
  description = "basic security group"
}

# allow ping
resource "huaweicloud_networking_secgroup_rule" "allow_ping" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = huaweicloud_networking_secgroup.secgroup_oc.id
}

# allow https
resource "huaweicloud_networking_secgroup_rule" "allow_https" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = huaweicloud_networking_secgroup.secgroup_oc.id
}

# allow http
resource "huaweicloud_networking_secgroup_rule" "allow_http" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = huaweicloud_networking_secgroup.secgroup_oc.id
}


# create database security group
resource "huaweicloud_networking_secgroup" "secgroup_oc_database" {
  name        = "Secgroup-database-OC"
  description = "basic security group"
}

resource "huaweicloud_networking_secgroup_rule" "allow_db_3306_web_subnet_1" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 3306
  port_range_max    = 3306
  remote_ip_prefix  = huaweicloud_vpc_subnet.web_subnet_1.cidr
  security_group_id = huaweicloud_networking_secgroup.secgroup_oc_database.id
}
resource "huaweicloud_networking_secgroup_rule" "allow_db_3306_web_subnet_2" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 3306
  port_range_max    = 3306
  remote_ip_prefix  = huaweicloud_vpc_subnet.web_subnet_2.cidr
  security_group_id = huaweicloud_networking_secgroup.secgroup_oc_database.id
}


# Create two ECS reside in web subnet
data "huaweicloud_compute_flavors" "myflavor" {
  availability_zone = data.huaweicloud_availability_zones.myaz.names[2]
  performance_type  = "normal"
#   generation = "s6"
  cpu_core_count    = 1
  memory_size       = 1
}



data "huaweicloud_images_image" "myimage" {
  name        = "Ubuntu 18.04 server 64bit"
  most_recent = true
}


resource "huaweicloud_compute_instance" "ecs_01" {
  name              = "terraform_ecs_test_oc_01"
  admin_pass        = "Oc1234@@"
  image_id          = data.huaweicloud_images_image.myimage.id
  flavor_id = "s6.small.1"
  depends_on = [
    huaweicloud_networking_secgroup.secgroup_oc
  ]
  security_groups   = [huaweicloud_networking_secgroup.secgroup_oc.name]
  availability_zone   = "cn-south-1c"
  network {
    uuid = huaweicloud_vpc_subnet.web_subnet_1.id
  }
}

resource "huaweicloud_compute_instance" "ecs_02" {
  name              = "terraform_ecs_test_oc_02"
  admin_pass        = "Oc1234@@"
  image_id          = data.huaweicloud_images_image.myimage.id
  flavor_id = "s6.small.1"
  depends_on = [
    huaweicloud_networking_secgroup.secgroup_oc
  ]
  security_groups   = [huaweicloud_networking_secgroup.secgroup_oc.name]
  availability_zone   = "cn-south-1e"
  network {
    uuid = huaweicloud_vpc_subnet.web_subnet_2.id
  }
}


# Create Load balancer

data "huaweicloud_elb_flavors" "l7_flavors" {
  type            = "L7"
  max_connections = 200000
  cps             = 2000
  bandwidth       = 50
}
data "huaweicloud_elb_flavors" "l4_flavors" {
  type            = "L4"
  max_connections = 500000
  cps             = 10000
  bandwidth       = 50
}

resource "huaweicloud_elb_loadbalancer" "Terraform_OC" {
  name              = "Terraform_OC_ELB"
  description       = "Terraform_OC"
  cross_vpc_backend = true

  vpc_id            = huaweicloud_vpc.vpc_basic.id
  # ipv6_network_id   = "{{ ipv6_network_id }}"
  # ipv6_bandwidth_id = "{{ ipv6_bandwidth_id }}"
  ipv4_subnet_id    = huaweicloud_vpc_subnet.web_subnet_2.subnet_id

  l4_flavor_id = data.huaweicloud_elb_flavors.l4_flavors.ids[0]
  l7_flavor_id = data.huaweicloud_elb_flavors.l7_flavors.ids[0]

  availability_zone = [
   "cn-south-1e",
   "cn-south-1f",
   "cn-south-1c"
  ]



  iptype                = "5_bgp"
  bandwidth_charge_mode = "traffic"
  sharetype             = "PER"
  bandwidth_size        = 10
}


resource "huaweicloud_elb_listener" "Terraform_OC_Test_Listener" {
  name            = "basic"
  description     = "basic description"
  protocol        = "HTTP"
  protocol_port   = 80
  loadbalancer_id = huaweicloud_elb_loadbalancer.Terraform_OC.id

  idle_timeout     = 60
  request_timeout  = 60
  response_timeout = 60

}

resource "huaweicloud_elb_pool" "pool_80_port" {
  name = "pool_80_port"
  protocol    = "HTTP"
  lb_method   = "ROUND_ROBIN"
  depends_on = [
    huaweicloud_elb_listener.Terraform_OC_Test_Listener
  ]
  listener_id = huaweicloud_elb_listener.Terraform_OC_Test_Listener.id

  
}

resource "huaweicloud_elb_monitor" "monitor_1" {
  protocol    = "HTTP"
  interval    = 30
  timeout     = 15
  max_retries = 10
  url_path    = "/"
  port        = 80
  pool_id     = huaweicloud_elb_pool.pool_80_port.id
}

resource "huaweicloud_elb_member" "member_1" {
  address       = huaweicloud_compute_instance.ecs_01.network[0].fixed_ip_v4
  protocol_port = 80
  pool_id       = huaweicloud_elb_pool.pool_80_port.id
  subnet_id     = huaweicloud_vpc_subnet.web_subnet_1.ipv4_subnet_id
}
resource "huaweicloud_elb_member" "member_2" {
  address       = huaweicloud_compute_instance.ecs_02.network[0].fixed_ip_v4
  protocol_port = 80
  pool_id       = huaweicloud_elb_pool.pool_80_port.id
  subnet_id     = huaweicloud_vpc_subnet.web_subnet_2.ipv4_subnet_id
}


#  Create database 
resource "huaweicloud_rds_instance" "instance" {
  name                = "terraform_test_rds_instance"
  flavor              = "rds.pg.n1.large.2.ha"
  ha_replication_mode = "async"
  vpc_id              = huaweicloud_vpc.vpc_basic.id
  subnet_id           = huaweicloud_vpc_subnet.database_subnet_1.id
  security_group_id   = huaweicloud_networking_secgroup.secgroup_oc_database.id
  availability_zone   = [
    "cn-south-1c",
    "cn-south-1e"]

  db {
    type     = "PostgreSQL"
    version  = "12"
    password = "Huangwei!120521"
  }
  volume {
    type = "CLOUDSSD"
    size = 100
  }
  backup_strategy {
    start_time = "08:00-09:00"
    keep_days  = 1
  }
}



# resource "huaweicloud_er_instance" "OC_TEST_ER" {
#   availability_zones = ["cn-south-1f","cn-south-1e"]
#   name = "OC_TEST_ER"
#   asn = 64513
#   enable_default_propagation = true
#   enable_default_association = true
#   auto_accept_shared_attachments = true
# }








