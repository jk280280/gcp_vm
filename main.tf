resource "google_compute_instance" "secure_instance" {
  project = var.project_id
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    auto_delete = true
    initialize_params {
      image = "projects/debian-cloud/global/images/debian-12-bookworm-v20250212"
      size  = 10  # Increased disk size for better performance
      type  = "pd-balanced"
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
    ]  # Limited IAM permissions for security
  }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = true  # Secure boot enabled
    enable_vtpm                 = true
  }

  labels = {
    environment = "production"
  }

  tags = ["http-server", "https-server"]
}

module "ops_agent_policy" {
  source        = "github.com/terraform-google-modules/terraform-google-cloud-operations/modules/ops-agent-policy"
  project       = var.project_id
  zone          = var.zone
  assignment_id = "goog-ops-agent-secure"
  agents_rule = {
    package_state = "installed"
    version       = "latest"
  }
  instance_filter = {
    all = false
    inclusion_labels = [{
      labels = {
        environment = "production"
      }
    }]
  }
}
