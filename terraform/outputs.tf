output "external_ip_address_app1" {
  value = yandex_compute_instance.app1.network_interface.0.nat_ip_address
}

output "external_ip_address_app2" {
  value = yandex_compute_instance.app2.network_interface.0.nat_ip_address
}

output "external_ip_address_lb" {
  #  value = [for s in yandex_lb_network_load_balancer.lb.listener : s if s != "external_address_spec"]
  value = yandex_lb_network_load_balancer.lb.listener
}
