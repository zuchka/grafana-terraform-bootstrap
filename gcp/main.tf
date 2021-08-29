terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.80.0"
    }
  }
}

provider "google" {
  credentials = file(var.credentials_file)

  project = var.project
  region  = var.region
  zone    = var.zone
}

resource "google_compute_address" "ip_address" {
  name = "foo-address"
}

resource "google_compute_firewall" "default" {
  name    = "grafana-port"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["3000"]
  }
}

resource "google_compute_instance" "instance_with_ip" {
  name         = "grafana-box"
  # this should be determined dynamically
  # only devenv needs this much power
  # the others could use a micro instance probably (2 vCPU)
#  machine_type = "e2-standard-16"
  machine_type = "${var.machine_type}-standard-${var.cpu_count}"
  # machine_type = "n2d-standard-2"
  # zone         = "us-central1-a"

  provisioner "remote-exec" {
    script = "./scripts/${var.workflow}.sh"

    connection {
      type = "ssh"
      user = "grafana"
      host = self.network_interface[0].access_config[0].nat_ip
    }
  }

  boot_disk {
    initialize_params {
      image = "${var.image_family}/${var.image_project}"
      size  = 25
    }
  }
  
  network_interface {
    network = "default"
    access_config {
      nat_ip = google_compute_address.ip_address.address
    }
  }

  metadata = {
    sshKeys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
  }
}

# print ip address to console here?
