variable "tenancy_ocid" {
  type        = string
  description = "Tenancy OCID"
}

variable "user_ocid" {
  type        = string
  description = "User OCID"
}

variable "fingerprint" {
  type        = string
  description = "API key fingerprint"
}

variable "region" {
  type        = string
  description = "Oracle Cloud Region"
  default     = "eu-frankfurt-1"
}

variable "private_key_path" {
  type        = string
  description = "Path to the private key .pem file"
  default     = "./oci_api_key.pem"
}
