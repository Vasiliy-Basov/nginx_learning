provider "google" {
  credentials = file(var.credentials_path)
  project = var.project
  region  = var.region
}

# Определение IP-адреса для инстанса
resource "google_compute_address" "nginx-learn-ip" {
  name = "nginx-learn-ip"
  project = var.project
  region  = var.region 
  address_type = "EXTERNAL" 
}

# Добавляем публичный ssh-key для подключения provisioner по ssh
resource "google_compute_project_metadata" "ssh_keys" {
  metadata = {
    ssh-keys = "appuser:${chomp(file(var.public_key))}"
  }
}

resource "google_compute_instance" "nginx-learn" {
  name         = "nginx-learn"
  machine_type = "g1-small"
  zone         = var.zone
  tags         = ["nginx", "http-server", "https-server"]
  labels = {
    ansible_group = "nginx"  # можем определить labels по ним будет работать ansible
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
      nat_ip = google_compute_address.nginx-learn-ip.address
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

  /* provisioner "local-exec" {
    command = "ansible-playbook -i ${self.network_interface[0].access_config[0].nat_ip}, --private-key ${var.private_key} nginx.yaml"
  }
  provisioner "local-exec" {
    command = "ansible-playbook -i ${self.network_interface[0].access_config[0].nat_ip}, --private-key ${var.private_key} nginx.yaml"
  } */
}

// DNS-запись типа A для корневого домена, указывающая на IP-адрес инстанса
resource "google_dns_record_set" "nginx_basov_world" {
  name        = "nginx.basov.world."
  type        = "A"
  ttl         = 300
  managed_zone = "basov-world"
  rrdatas     = [google_compute_address.nginx-learn-ip.address]
}

// DNS-запись типа CNAME для www-домена, указывающая на корневой домен
resource "google_dns_record_set" "www_nginx_basov_world" {
  name        = "www.nginx.basov.world."
  type        = "CNAME"
  ttl         = 300
  managed_zone = "basov-world"
  rrdatas     = ["nginx.basov.world."]
}
