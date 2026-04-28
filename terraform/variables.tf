variable "tenancy_ocid" {
  type        = string
  description = "OCID da Tenancy"
}

variable "user_ocid" {
  type        = string
  description = "OCID do Utilizador"
}

variable "fingerprint" {
  type        = string
  description = "Fingerprint da chave API"
}

variable "region" {
  type        = string
  description = "Região da Oracle Cloud"
  default     = "eu-frankfurt-1"
}

variable "private_key_path" {
  type        = string
  description = "Caminho para o ficheiro .pem da chave privada"
  default     = "./oci_api_key.pem"
}
