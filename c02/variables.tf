variable "key_name" {
  type    = string
  default = "LlaveKark" // <- reemplazar por el nombre de tu keypair
}
variable "google_db_name" {
  description = "Name of the Google DB"
  default     = "google"
}

variable "google_db_user" {
  description = "User for the Google DB"
  default     = "dbuser"
}

variable "google_db_password" {
  description = "Password for the Google DB"
  type        = string
  sensitive   = true
}

variable "metabase_password" {
  description = "Password for Metabase"
  type        = string
  sensitive   = true
}

variable "admin_email" {
  description = "Admin email for Metabase"
  type        = string
  sensitive   = true
 
}
