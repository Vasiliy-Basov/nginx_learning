variable "project" {
  # Описание переменной
  description = "Project ID"
  default = "micro-386716"
}

variable "region" {
  description = "Region"
  default = "us-central1"
  # Значение по умолчанию
}

variable "zone" {
  # zone location for google_compute_instance app
  description = "Zone location"
  default     = "us-central1-c"
}

variable "node_count" {
  description = "Initial node count"
  default     = 1
}

variable "k8s_cluster_name" {
  description = "Kubernetes cluster name"
  default     = "k8s-test"
}

variable "k8s_ingress_ip" {
  description = "Kubernetes ingress ip"
  default     = "k8s-ingress-ip"
}

variable "machine_type" {
  description = "Kubernetes node machine type"
  default     = "n2-standard-2"
}

variable "disk_size_gb" {
  description = "Kubernetes node disk size"
  default     = 40
}

variable "k8s_node_pool_name" {
  description = "Kubernetes node pool name"
  default     = "k8s-node-pool"
}
