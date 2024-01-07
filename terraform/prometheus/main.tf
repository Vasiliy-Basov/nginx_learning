provider "google" {
  credentials = file(var.credentials_path)
  project     = var.project
  region      = var.region
}

# Выделение IP-адреса для инстансов
resource "google_compute_address" "prometheus" {
  count       = var.instance_count
  name        = "prometheus-${count.index + 1}"
  project     = var.project
  region      = var.region
  address_type = "EXTERNAL"
}

# Добавляем публичный ssh-key для подключения provisioner по ssh
resource "google_compute_project_metadata" "ssh_keys" {
  metadata = {
    ssh-keys = "appuser:${chomp(file(var.public_key))}"
  }
}

resource "google_compute_instance" "prometheus" {
  count        = var.instance_count
  name         = "prometheus-${count.index + 1}"
  machine_type = "g1-small"
  zone         = var.zone
  tags         = ["nginx", "http-server", "https-server"]
  labels = {
    ansible_group = "prometheus"
    env           = "learn"
  }

  boot_disk {
    initialize_params {
      image = var.disk_image
      size  = 40
    }
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = google_compute_address.prometheus[count.index].address
    }
  }

  provisioner "remote-exec" {
    inline = ["echo 'Wait until SSH is ready'"]

    connection {
      type        = "ssh"
      user        = var.ssh_user
      private_key = file(var.private_key)
      host        = self.network_interface[0].access_config[0].nat_ip
    }
  }
}

resource "google_dns_record_set" "prometheus" {
  count       = var.instance_count
  name        = "prometheus-${count.index + 1}.basov.world."
  type        = "A"
  ttl         = 300
  managed_zone = "basov-world"
  rrdatas     = [google_compute_address.prometheus[count.index].address]
}

resource "google_dns_record_set" "www_prometheus" {
  count       = var.instance_count
  name        = "www.prometheus-${count.index + 1}.basov.world."
  type        = "CNAME"
  ttl         = 300
  managed_zone = "basov-world"
  rrdatas     = ["${google_dns_record_set.prometheus[count.index].name}"]
}
