variable "zone" {
  description = "Zone"
  default     = "ru-central1-a"
}

variable "db_disk_image_id" {
  description = "Disk image id for VM (db)"
}

variable "public_key_path" {
  description = "Path to the public key used for ssh access"
}

variable "subnet_id" {
  description = "ID for subnet"
}

variable "environment" {
  description = "Current environment (stage, prod, etc)"
}
