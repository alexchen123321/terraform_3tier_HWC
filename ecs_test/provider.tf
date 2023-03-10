provider "huaweicloud" {
  region     = module.global_vars.default_region
  access_key = module.global_vars.common_service_account_ak
  secret_key = module.global_vars.common_service_account_sk
}