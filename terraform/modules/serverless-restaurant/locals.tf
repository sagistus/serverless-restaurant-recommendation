locals {

  restaurant_styles   = "Italian,French,Korean,Japanese,Mexican"
  vegetarian_keywords = "vegetarian,veggie"
  delivery_keywords   = "delivery,deliveries,delivers"
  cw_log_group_name   = "/aws/lambda/restaurantRecommendationFunction-${var.environment}"
  secret_name         = "${var.environment}/restaurant_db_credentials"
  common_tags = {
    Environment = var.environment
  }
}
