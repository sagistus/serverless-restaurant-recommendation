variable "environment" {
  type    = string
  default = "dev"
}

variable "aws_region" {
  default = "us-east-1"
}

variable "db_host" {
  type = string
}

variable "db_port" {
  type    = string
  default = "5432"
}

variable "db_name" {
  type    = string
  default = "resturants_info"
}

variable "db_user" {
  type      = string
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
}
