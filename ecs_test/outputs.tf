output "vpc_id" {
  value       = huaweicloud_vpc.vpc_basic.id
  description = "VPC ID"
}

output "myaz1" {
  value      = data.huaweicloud_availability_zones.myaz.names[1]
}

output "myaz2" {
  value      = data.huaweicloud_availability_zones.myaz.names[2]
}

output "myaz3" {
  value      = data.huaweicloud_availability_zones.myaz.names[3]
}