provider "aws" {
  region = "us-east-1"
}

module "restaurant_us_east_1" {
  source = "../..//modules/serverless-restaurant"
  db_host = var.db_host
  db_password = var.db_password
  db_user = var.db_user
}
