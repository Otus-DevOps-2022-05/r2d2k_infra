provider "yandex" {
  service_account_key_file = var.service_account_key_file
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone
}

module "app" {
  source            = "../modules/app"
  public_key_path   = var.public_key_path
  app_disk_image_id = var.app_disk_image_id
  subnet_id         = var.subnet_id
  zone              = var.zone
  environment       = var.environment
}

module "db" {
  source           = "../modules/db"
  public_key_path  = var.public_key_path
  db_disk_image_id = var.db_disk_image_id
  subnet_id        = var.subnet_id
  zone             = var.zone
  environment      = var.environment
}