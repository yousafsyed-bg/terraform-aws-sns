module "utils" {
  source      = "git::https://github.com/automatiq-team/terraform-aws-utils.git?ref=v0.1.4"
  region      = var.region
  environment = var.environment
  team        = var.owner
  service     = var.service
  product     = var.product
  costtype    = var.costtype
}