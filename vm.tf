terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

# Variables
variable "snapshot_name" {
  description = "Name of the snapshot to restore from. Leave empty for fresh install."
  type        = string
  default     = ""
}

variable "project_id" {
  description = "GCP Project ID"
  type        = string
  default     = "your-gcp-project-name"
}

# Provider
provider "google" {
  project = var.project_id
  region  = "us-central1"
}

# Data source for snapshot (if it exists)
data "google_compute_snapshot" "decidim_snapshot" {
  count   = var.snapshot_name != "" ? 1 : 0
  name    = var.snapshot_name
  project = var.project_id
}

resource "google_compute_disk" "boot_disk" {
  name    = "decidim-boot-disk"
  zone    = "us-central1-a"
  type    = "pd-ssd"
  size    = 50

  snapshot = var.snapshot_name != "" ? var.snapshot_name : null
  image    = var.snapshot_name == "" ? "ubuntu-os-cloud/ubuntu-2204-lts" : null
}

# VM Instance
resource "google_compute_instance" "decidim_vm" {
  name         = "decidim-vm"
  machine_type = "e2-standard-4"
  zone         = "us-central1-a"

  boot_disk {
    source = google_compute_disk.boot_disk.self_link
  }

  network_interface {
    network = "default"
    access_config {
      # This empty block assigns a public IP
    }
  }

    metadata_startup_script = var.snapshot_name == "" ? "#!/bin/bash\napt-get update\napt-get install -y docker.io docker-compose\nsystemctl start docker\nsystemctl enable docker" : ""

  tags = ["http-server", "https-server"]
}

# Firewall rules
resource "google_compute_firewall" "decidim" {
  name    = "decidim-firewall"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["3000", "80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server", "https-server"]
}

# Outputs
output "instance_ip" {
  description = "The public IP of the VM instance"
  value       = google_compute_instance.decidim_vm.network_interface[0].access_config[0].nat_ip
}
