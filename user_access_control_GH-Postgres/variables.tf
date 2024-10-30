# Universal
variable "GITHUB_TOKEN" {
  description = "GitHub Token for Robopony"
}

variable "AWS_REGION" {
  description = "Default AWS Region"
}

variable "AWS_ACCOUNT_ID" {
  description = "AWS Account ID"
}

# Doppler
variable "DOPPLER_STAGING_TOKEN" {
  description = "The Doppler cred for Demo_App - Staging"
}
variable "DOPPLER_PROD_TOKEN" {
  description = "The Doppler cred for Demo_App - Production"
}

# Postgres
variable "STAGING_DB_HOST" {
  description = "Postgres host - Production"
}
variable "PROD_DB_HOST" {
  description = "Postgres host - Production"
}
variable "DB_NAME" {
  description = "Demo_App db"
}
variable "DB_USER" {
  description = "Demo_App Admin"
}
variable "DB_PASSWORD" {
  description = "Demo_App Admin"
}
