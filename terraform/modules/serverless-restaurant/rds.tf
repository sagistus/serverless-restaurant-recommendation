module "rds" {
  source          = "terraform-aws-modules/rds/aws"
  version         = "~> 3.0"
  engine          = "postgres"
  engine_version  = "13.3"
  instance_class  =  var.environment == "prod" ? "db.m5.large" : "db.t3.micro"
  allocated_storage = 20
  max_allocated_storage	 = 100
  storage_encrypted	 = true
  kms_key_id = aws_kms_key.cmk.id
  username        = var.db_user
  password        = var.db_password
  subnet_ids       = data.aws_subnets.private_subnets.id
  db_subnet_group_name = "restaurant-db-subnet-group"
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  multi_az          = var.environment == "prod" ? true : false
  backup_retention_period = var.environment == "prod" ? 7 : 3
  tags = local.common_tags
  identifier = "resturant"
}
