variable "service_account_key_file" {
  description = "Path to service account key file"
}

variable "cloud_id" {
  description = "Cloud"
}

variable "folder_id" {
  description = "Folder"
}

variable "zone" {
  description = "Zone"
  default     = "ru-central1-a"
}

variable "image_id" {
  description = "Image id for VM"
}

variable "app_disk_image_id" {
  description = "Disk image id for VM (app)"
}

variable "db_disk_image_id" {
  description = "Disk image id for VM (db)"
}

variable "subnet_id" {
  description = "ID for subnet"
}

variable "public_key_path" {
  description = "Path to the public key used for ssh access"
}

variable "private_key_path" {
  description = "Path to the private key used for ssh access"
}

variable "environment" {
  description = "Current environment (stage, prod, etc)"
}

variable "deploy_needed" {
  description = "Deploy application if set to 'true'"
  type        = bool
  default     = false
}

variable "ipv4_subnet_blocks" {
  description = "Address blocks for subnet"
}
