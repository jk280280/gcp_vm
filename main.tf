resource "google_compute_instance" "secure_instance" {
  project      = var.project_id
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    auto_delete = true
    initialize_params {
      image = "projects/debian-cloud/global/images/debian-12-bookworm-v20250212"
      size  = 20  # Increased disk size for better performance
      type  = "pd-ssd"  # Changed to SSD for faster I/O
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
    enable-oslogin = "TRUE"  # Enforce OS Login for secure SSH access
  }

  metadata_startup_script = <<EOT
    #!/bin/bash
    sudo apt update -y && sudo apt install -y curl unzip
    echo "Downloading Harness Delegate..."
    curl -L -o harness-delegate.tar.gz "https://app.harness.io/storage/harness-download/delegate.tar.gz"
    
    echo "Extracting and Installing..."
    mkdir /opt/harness-delegate && tar -xvzf harness-delegate.tar.gz -C /opt/harness-delegate
    
    echo "Starting Harness Delegate..."
    cd /opt/harness-delegate
    nohup ./start.sh > /var/log/harness-delegate.log 2>&1 &
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

  source_ranges = ["YOUR_IP/32"]  # Restrict SSH to your IP
  target_tags   = ["harness-delegate"]
}

