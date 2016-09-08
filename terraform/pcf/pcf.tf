//// Declare vars

variable "gcp_proj_id" {}
variable "gcp_region" {}
variable "gcp_terraform_prefix" {}
variable "gcp_terraform_subnet_bosh" {}
variable "gcp_zone_1" {}
variable "gcp_zone_2" {}
variable "gcp_zone_3" {}
variable "gcp_terraform_subnet_concourse" {}
variable "gcp_terraform_subnet_vault" {}
variable "gcp_terraform_subnet_pcf_zone1" {}
variable "gcp_terraform_subnet_pcf_zone2" {}
variable "pcf_ert_sys_domain" {}
variable "gcp_svc_acct_key" {}

//// Set GCP Provider info

provider "google" {
  project = "${var.gcp_proj_id}"
  region = "${var.gcp_region}"
  # zone1 = "${var.gcp_zone_1}"
  # zone2 = "${var.gcp_zone_2}"
  # zone3 = "${var.gcp_zone_3}"
  credentials = "${var.gcp_svc_acct_key}"
}

/////////////////////////////////
//// Create Network Objects   ///
/////////////////////////////////

  //// Create GCP Virtual Network
  resource "google_compute_network" "vnet" {
    name       = "${var.gcp_terraform_prefix}-vnet"
  }

  //// Create CloudFoundry Static IP address
  resource "google_compute_address" "cloudfoundry-public-ip" {
    name   = "${var.gcp_terraform_prefix}-cloudfoundry-public-ip"
    region = "${var.gcp_region}"
  }

  //// Create Concourse Static IP address
  resource "google_compute_address" "concourse-public-ip" {
    name   = "${var.gcp_terraform_prefix}-concourse-public-ip"
    region = "${var.gcp_region}"
  }

  //// Create Subnet for the BOSH director
  resource "google_compute_subnetwork" "subnet-bosh" {
    name          = "${var.gcp_terraform_prefix}-subnet-bosh-${var.gcp_region}"
    ip_cidr_range = "${var.gcp_terraform_subnet_bosh}"
    network       = "${google_compute_network.vnet.self_link}"
  }

  //// Create Subnet for Concourse
  resource "google_compute_subnetwork" "subnet-concourse" {
    name          = "${var.gcp_terraform_prefix}-subnet-concourse-${var.gcp_zone_1}"
    ip_cidr_range = "${var.gcp_terraform_subnet_concourse}"
    network       = "${google_compute_network.vnet.self_link}"
  }

  //// Create Subnet for Vault
  resource "google_compute_subnetwork" "subnet-vault" {
    name          = "${var.gcp_terraform_prefix}-subnet-vault-${var.gcp_zone_1}"
    ip_cidr_range = "${var.gcp_terraform_subnet_vault}"
    network       = "${google_compute_network.vnet.self_link}"
  }

  //// Create Subnet for ERT
  resource "google_compute_subnetwork" "subnet-pcf" {
    name          = "${var.gcp_terraform_prefix}-subnet-pcf-${var.gcp_region}"
    ip_cidr_range = "${var.gcp_terraform_subnet_pcf_zone1}"
    network       = "${google_compute_network.vnet.self_link}"
  }

  //// Create Firewall Rule for allow-ssh
  resource "google_compute_firewall" "allow-ssh" {
    name    = "${var.gcp_terraform_prefix}-allow-ssh"
    network = "${google_compute_network.vnet.name}"
    allow {
      protocol = "tcp"
      ports    = ["22"]
    }
    allow {
      protocol = "icmp"
    }
    source_ranges = ["0.0.0.0/0"]
    source_tags = ["allow-ssh"]
  }

  //// Create Firewall Rule for nat-traverse
  resource "google_compute_firewall" "nat-traverse" {
    name    = "${var.gcp_terraform_prefix}-nat-traverse"
    network = "${google_compute_network.vnet.name}"

    allow {
      protocol = "icmp"
    }

    allow {
      protocol = "tcp"
    }

    allow {
      protocol = "udp"
    }
    target_tags = ["nat-traverse"]
    source_tags = ["nat-traverse"]
  }

  //// Create Firewall Rule for concourse
  resource "google_compute_firewall" "concourse" {
    name    = "${var.gcp_terraform_prefix}-concourse"
    network = "${google_compute_network.vnet.name}"
    allow {
      protocol = "icmp"
    }
    allow {
      protocol = "tcp"
      ports    = ["8080","4443"]
    }
    source_ranges = ["0.0.0.0/0"]
    target_tags = ["concourse-public"]
}

  //// Create Firewall Rule for PCF
  resource "google_compute_firewall" "pcf-public" {
    name    = "${var.gcp_terraform_prefix}-pcf-public"
    network = "${google_compute_network.vnet.name}"
    allow {
      protocol = "icmp"
    }
    allow {
      protocol = "tcp"
      ports    = ["80","443", "4443"]
    }
    source_ranges = ["0.0.0.0/0"]
    target_tags = ["pcf-public"]
}

  //// Create Firewall Rule for PCF - SSH
  resource "google_compute_firewall" "pcf-public-ssh" {
    name    = "${var.gcp_terraform_prefix}-pcf-public-ssh"
    network = "${google_compute_network.vnet.name}"
    allow {
      protocol = "icmp"
    }
    allow {
      protocol = "tcp"
      ports    = ["2222"]
    }
    source_ranges = ["0.0.0.0/0"]
    target_tags = ["pcf-public-ssh"]
}

  //// Create HTTP Health Check Rule for PCF
  resource "google_compute_http_health_check" "pcf-public" {
  name         = "${var.gcp_terraform_prefix}-pcf-public"
  request_path = "/v2/info"
  host         = "api.${var.pcf_ert_sys_domain}"
  port         = 80

  healthy_threshold   = 10
  unhealthy_threshold = 2
  timeout_sec         = 5
  check_interval_sec  = 30
}

  //// Create HTTP Health Check Rule for Concourse
  resource "google_compute_http_health_check" "concourse-public" {
  name         = "${var.gcp_terraform_prefix}-concourse-public"
  request_path = "/"
  host         = ""
  port         = 8080

  healthy_threshold   = 10
  unhealthy_threshold = 2
  timeout_sec         = 5
  check_interval_sec  = 30
}

  //// Create Target Pool for PCF
  resource "google_compute_target_pool" "pcf-public" {
  name          = "${var.gcp_terraform_prefix}-pcf-public"
  health_checks = [
    "${google_compute_http_health_check.pcf-public.name}",
  ]
}

  //// Create Target Pool for PCF - SSH
  resource "google_compute_target_pool" "pcf-public-ssh" {
  name          = "${var.gcp_terraform_prefix}-pcf-public-ssh"
}

  //// Create Target Pool for Concourse
  resource "google_compute_target_pool" "concourse-public" {
  name          = "${var.gcp_terraform_prefix}-concourse-public"
  health_checks = [
    "${google_compute_http_health_check.concourse-public.name}",
  ]
}

  //// Create Forwarding for PCF - http
  resource "google_compute_forwarding_rule" "pcf-http" {
  name       = "${var.gcp_terraform_prefix}-pcf-http"
  target     = "${google_compute_target_pool.pcf-public.self_link}"
  ip_address = "${google_compute_address.cloudfoundry-public-ip.address}"
  port_range = "80"
}

  //// Create Forwarding for PCF - https
  resource "google_compute_forwarding_rule" "pcf-https" {
  name       = "${var.gcp_terraform_prefix}-pcf-https"
  target     = "${google_compute_target_pool.pcf-public.self_link}"
  ip_address = "${google_compute_address.cloudfoundry-public-ip.address}"
  port_range = "443"
}

  //// Create Forwarding for PCF - ssh
  resource "google_compute_forwarding_rule" "pcf-ssh" {
  name       = "${var.gcp_terraform_prefix}-pcf-ssh"
  target     = "${google_compute_target_pool.pcf-public-ssh.self_link}"
  ip_address = "${google_compute_address.cloudfoundry-public-ip.address}"
  port_range = "2222"
}

  //// Create Forwarding for PCF - wss
  resource "google_compute_forwarding_rule" "pcf-wss" {
  name       = "${var.gcp_terraform_prefix}-pcf-wss"
  target     = "${google_compute_target_pool.pcf-public.self_link}"
  ip_address = "${google_compute_address.cloudfoundry-public-ip.address}"
  port_range = "4443"
}

  //// Create Forwarding for Concourse - http
  resource "google_compute_forwarding_rule" "concourse-http" {
  name       = "${var.gcp_terraform_prefix}-concourse-http"
  target     = "${google_compute_target_pool.concourse-public.self_link}"
  ip_address = "${google_compute_address.concourse-public-ip.address}"
  port_range = "8080"
}

  //// Create Forwarding for Concourse - https
  resource "google_compute_forwarding_rule" "concourse-https" {
  name       = "${var.gcp_terraform_prefix}-concourse-https"
  target     = "${google_compute_target_pool.concourse-public.self_link}"
  ip_address = "${google_compute_address.concourse-public-ip.address}"
  port_range = "4443"
}

/////////////////////////////////////
//// Create BOSH bastion instance ///
/////////////////////////////////////

resource "google_compute_instance" "bosh-bastion" {
  name         = "${var.gcp_terraform_prefix}-bosh-bastion"
  machine_type = "n1-standard-1"
  zone         = "${var.gcp_zone_1}"

  tags = ["${var.gcp_terraform_prefix}-instance", "nat-traverse", "allow-ssh"]

  disk {
    image = "ubuntu-1404-trusty-v20160610"
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.subnet-bosh.name}"
    access_config {
      // Ephemeral
    }
  }

  service_account {
    #scopes = ["cloud-platform"]
    scopes = [
              "https://www.googleapis.com/auth/logging.write",
              "https://www.googleapis.com/auth/monitoring.write",
              "https://www.googleapis.com/auth/servicecontrol",
              "https://www.googleapis.com/auth/service.management.readonly",
              "https://www.googleapis.com/auth/devstorage.full_control"
            ]
  }

  metadata {
    zone="${var.gcp_zone_1}"
    region="${var.gcp_region}"
  }

  metadata_startup_script = <<EOF

#! /bin/bash
adduser --disabled-password --gecos "" bosh
apt-get update -y
apt-get upgrade -y
apt-get install -y build-essential zlibc zlib1g-dev ruby ruby-dev openssl libxslt-dev libxml2-dev libssl-dev libreadline6 libreadline6-dev libyaml-dev libsqlite3-dev sqlite3
wget "https://cli.run.pivotal.io/stable?release=debian64&source=github" -O /tmp/cf-cli.deb
dpkg --install /tmp/cf-cli.deb
wget $(wget -q -O- https://bosh.io/docs/install-bosh-init.html | grep "bosh-init for Linux (amd64)" | awk -F "\'" '{print$2}') -O /sbin/bosh-init
chmod 755 /sbin/bosh-init
tar -zxvf /tmp/cf.tgz && mv cf /usr/bin/cf && chmod +x /usr/bin/cf
gcloud config set compute/zone $zone
gcloud config set compute/region $region
mkdir -p /home/bosh/.ssh
ssh-keygen -t rsa -f /home/bosh/.ssh/bosh -C bosh -N ''
sed '1s/^/bosh:/' /home/bosh/.ssh/bosh.pub > /home/bosh/.ssh/bosh.pub.gcp
chown -R bosh:bosh /home/bosh/.ssh
gcloud compute project-info add-metadata --metadata-from-file sshKeys=/home/bosh/.ssh/bosh.pub.gcp
gem install bosh_cli
gem install cf-uaac
EOF

}

/////////////////////////////////
//// Create NAT instance(s)   ///
/////////////////////////////////

//// NAT Pri
resource "google_compute_instance" "nat-gateway-pri" {
  name           = "${var.gcp_terraform_prefix}-nat-gateway-pri"
  machine_type   = "n1-standard-1"
  zone           = "${var.gcp_zone_1}"
  can_ip_forward = true
  tags = ["${var.gcp_terraform_prefix}-instance", "nat-traverse", "allow-ssh"]

  disk {
    image = "ubuntu-1404-trusty-v20160610"
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.subnet-bosh.name}"
    access_config {
      // Ephemeral
    }
  }

  metadata_startup_script = <<EOF
#! /bin/bash
sudo sh -c 'echo 1 > /proc/sys/net/ipv4/ip_forward'
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
EOF
}

//// NAT Sec

resource "google_compute_instance" "nat-gateway-sec" {
  name           = "${var.gcp_terraform_prefix}-nat-gateway-sec"
  machine_type   = "n1-standard-1"
  zone           = "${var.gcp_zone_2}"
  can_ip_forward = true
  tags = ["${var.gcp_terraform_prefix}-instance", "nat-traverse", "allow-ssh"]

  disk {
    image = "ubuntu-1404-trusty-v20160610"
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.subnet-bosh.name}"
    access_config {
      // Ephemeral
    }
  }

    metadata_startup_script = <<EOF
  #! /bin/bash
  sudo sh -c 'echo 1 > /proc/sys/net/ipv4/ip_forward'
  sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
  EOF
}

//// NAT Ter

resource "google_compute_instance" "nat-gateway-ter" {
  name           = "${var.gcp_terraform_prefix}-nat-gateway-ter"
  machine_type   = "n1-standard-1"
  zone           = "${var.gcp_zone_3}"
  can_ip_forward = true
  tags = ["${var.gcp_terraform_prefix}-instance", "nat-traverse", "allow-ssh"]

  disk {
    image = "ubuntu-1404-trusty-v20160610"
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.subnet-bosh.name}"
    access_config {
      // Ephemeral
    }
  }

  metadata_startup_script = <<EOF
#! /bin/bash
sudo sh -c 'echo 1 > /proc/sys/net/ipv4/ip_forward'
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
EOF

}

//// Create NAT Route

resource "google_compute_route" "nat-primary" {
  name        = "${var.gcp_terraform_prefix}-nat-pri"
  dest_range  = "0.0.0.0/0"
  network     = "${google_compute_network.vnet.name}"
  next_hop_instance = "${google_compute_instance.nat-gateway-pri.name}"
  next_hop_instance_zone = "${var.gcp_zone_1}"
  priority    = 800
  tags        = ["no-ip"]
}

resource "google_compute_route" "nat-secondary" {
  name        = "${var.gcp_terraform_prefix}-nat-sec"
  dest_range  = "0.0.0.0/0"
  network     = "${google_compute_network.vnet.name}"
  next_hop_instance = "${google_compute_instance.nat-gateway-sec.name}"
  next_hop_instance_zone = "${var.gcp_zone_2}"
  priority    = 801
  tags        = ["no-ip"]
}

resource "google_compute_route" "nat-tertiary" {
  name        = "${var.gcp_terraform_prefix}-nat-ter"
  dest_range  = "0.0.0.0/0"
  network     = "${google_compute_network.vnet.name}"
  next_hop_instance = "${google_compute_instance.nat-gateway-ter.name}"
  next_hop_instance_zone = "${var.gcp_zone_3}"
  priority    = 802
  tags        = ["no-ip"]
}

////Public IP Addresses
output "CloudFoundry IP Address" {
    value = "${google_compute_address.cloudfoundry-public-ip.address}"
}

output "Concourse IP Address" {
    value = "${google_compute_address.concourse-public-ip.address}"
}

output "Zone 1 - Concourse Subnet" {
    value = "${var.gcp_terraform_subnet_concourse}"
}

output "Zone 1 - CloudFoundry Subnet" {
    value = "${var.gcp_terraform_subnet_pcf_zone1}"
}

output "Zone 2 - CloudFoundry Subnet" {
    value = "${var.gcp_terraform_subnet_pcf_zone2}"
}
