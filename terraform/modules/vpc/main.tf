resource "yandex_vpc_network" "app-network" {
}

resource "yandex_vpc_subnet" "app-subnet" {
  zone           = var.zone
  network_id     = yandex_vpc_network.app-network.id
  v4_cidr_blocks = var.ipv4_subnet_blocks
}
