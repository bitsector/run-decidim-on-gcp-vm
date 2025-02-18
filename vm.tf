terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = "your-project-name"
  region  = "us-central1"
}

resource "google_compute_instance" "decidim_vm" {
  name         = "decidim-vm"
  machine_type = "e2-standard-4"  # 4 vCPUs, 16GB RAM
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 50  # 50GB disk
    }
  }

  network_interface {
    network = "default"
    access_config {
      # This empty block assigns a public IP
    }
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y docker.io docker-compose
    systemctl start docker
    systemctl enable docker
  EOF

  tags = ["http-server", "https-server"]
}

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
