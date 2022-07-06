variable "zone" {
  description = "Zone"
  default     = "ru-central1-a"
}

variable "app_disk_image_id" {
  description = "Disk image id for VM (app)"
}

variable "public_key_path" {
  description = "Path to the public key used for ssh access"
}

variable "subnet_id" {
  description = "ID for subnet"
}
