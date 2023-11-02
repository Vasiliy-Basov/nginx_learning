output "k8s_ingress_ip" {
    value       = google_compute_address.ingress_kubernetes_ip.address
    description = "The public IP address of ingress controller"
}
