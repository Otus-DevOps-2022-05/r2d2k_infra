output "external_ip_address_app" {
  value = yandex_compute_instance.app.network_interface.0.nat_ip_address
}

output "external_ip_address_lb" {
  #  value = [for s in yandex_lb_network_load_balancer.lb.listener : s if s != "external_address_spec"]
  value = yandex_lb_network_load_balancer.lb.listener
}
