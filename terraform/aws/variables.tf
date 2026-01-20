variable "account_id" {
  description = "(Required) The account ID to perform actions on."
  type        = string
}

variable "billing_tag_value" {
  description = "The billing code to tag our resources with"
  type        = string
}

variable "cbs_satellite_bucket_name" {
  description = "The Cloud Based Sensor bucket name"
  type        = string
}

variable "domain" {
  description = "The domain to use for the service."
  type        = string
}

variable "env" {
  description = "The current running environment"
  type        = string
}

variable "product_name" {
  description = "(Required) The name of the product you are deploying."
  type        = string
}

variable "region" {
  description = "The current AWS region"
  type        = string
}

variable "idp_admin_username" {
  description = "idp administrator username."
  type        = string
  sensitive   = true
}

variable "idp_admin_password" {
  description = "idp administrator password."
  type        = string
  sensitive   = true
}

variable "idp_cluster_capacity_provider" {
  description = "The capacity provider for the idp ECS cluster."
  type        = string
}

variable "idp_database" {
  description = "The name of the idp database."
  type        = string
  sensitive   = true
}

variable "idp_database_min_acu" {
  description = "The minimum serverless capacity for the database."
  type        = number
}

variable "idp_database_max_acu" {
  description = "The maximum serverless capacity for the database."
  type        = number
}

variable "idp_database_username" {
  description = "The idp username to use for the database."
  type        = string
  sensitive   = true
}

variable "idp_database_password" {
  description = "The idp password to use for the database."
  type        = string
  sensitive   = true
}

variable "idp_database_admin_username" {
  description = "The cluster's username to use for the database."
  type        = string
  sensitive   = true
}

variable "idp_database_admin_password" {
  description = "The cluster's admin password to use for the database."
  type        = string
  sensitive   = true
}

variable "idp_database_instance_count" {
  description = "The number of instances for the database cluster."
  type        = number
}

variable "idp_secret_key" {
  description = "The secret key to use for the idp instance."
  type        = string
  sensitive   = true
}

variable "idp_task_cpu" {
  description = "The CPU units for the idp ECS task."
  type        = number
}

variable "idp_task_desired_count" {
  description = "The desired number of idp ECS tasks."
  type        = number
}

variable "idp_task_max_capacity" {
  description = "The maximum autoscaling capacity for idp ECS tasks."
  type        = number
}

variable "idp_task_memory" {
  description = "The memory units for the idp ECS task."
  type        = number
}

variable "idp_task_min_capacity" {
  description = "The minimum autoscaling capacity for idp ECS tasks."
  type        = number
}
