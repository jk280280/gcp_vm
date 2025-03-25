terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_instance" "secure_instance" {
  project      = var.project_id
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    auto_delete = true
    initialize_params {
      image = "projects/debian-cloud/global/images/debian-12-bookworm-v20250212"
      size  = 20
      type  = "pd-ssd"
    }
  }

  network_interface {
    subnetwork = var.subnetwork
    access_config {
      network_tier = "PREMIUM"
    }
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    preemptible         = false
    provisioning_model  = "STANDARD"
  }

  service_account {
    email  = var.service_account_email
    scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write"
    ]
  }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = true
    enable_vtpm                 = true
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  metadata_startup_script = <<EOT
    #!/bin/bash
    set -e
    exec > >(tee /var/log/startup-script.log) 2>&1

    echo "Updating system packages..."
    sudo apt update -y && sudo apt install -y curl unzip docker.io

    echo "Enabling and starting Docker..."
    sudo systemctl enable docker
    sudo systemctl start docker
    sudo usermod -aG docker $(whoami)

    echo "Deploying Harness Delegate using Docker..."
    docker run  --cpus=1 --memory=2g \
      -e DELEGATE_NAME=docker-delegate \
      -e NEXT_GEN="true" \
      -e DELEGATE_TYPE="DOCKER" \
      -e ACCOUNT_ID=axO8S93qRGqqf1tlBaonnQ \
      -e DELEGATE_TOKEN=OWYyNDYzMjVlODVkZTJlY2RiZmFlZjM2NmEzMDk3N2Y= \
      -e DELEGATE_TAGS="" \
      -e MANAGER_HOST_AND_PORT=https://app.harness.io harness/delegate:25.03.85403
  EOT

  labels = {
    environment = "production"
  }

  tags = ["harness-delegate"]
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["harness-delegate"]
}
