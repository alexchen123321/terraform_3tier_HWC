variable "vpc_name" {
  type    = string
  default = "OneConnect_vpc_basic"
}

variable "vpc_cidr" {
  default = "172.16.10.0/24"
}

variable "subnet_name" {
  default = "terraform_subnet_basic"
}

variable "subnet_cidr" {
  default = "172.16.10.0/24"
}

variable "subnet_gateway" {
  default = "172.16.10.1"
}

variable "dns_list" {
  default = ["100.125.1.250","100.125.3.250"]
}

variable "flavor_id" {
  default = "s6.small.1"
}


# data "huaweicloud_availability_zones" "myaz" {}

# variable "ecs_names" {
#   type = map(object({
#     name = string
#     flavor_id = string
#     availability_zones = string
#   }))

#   default = {
#     "terraform_ecs1" = {
#       # availability_zones = "cn-south-1c"
#       flavor_id = "s6.small.1"
#       name = "terraform_ecs1"
#     },
#     "terraform_ecs2" = {
#       # availability_zones = "cn-south-1e"
#       flavor_id = "s6.medium.2"
#       name = "terraform_ecs2"
#     },
#     "terraform_ecs3" = {
#       # availability_zones = "cn-south-1f"
#       flavor_id = "s6.medium.4"
#       name = "terraform_ecs3"
#     }
  
#   }

# }
