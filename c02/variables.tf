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
  default     = "mypassword"
}

variable "metabase_password" {
  description = "Password for Metabase"
  default     = "metabasepassword1"
}
