output "nginx_global_ip_address" {
  value = google_compute_address.nginx-learn-ip.address
}
