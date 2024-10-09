resource "google_compute_network" "kirby" {
  name                    = "kirby-network"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  project                 = "oceanblue-web"
}

resource "google_compute_subnetwork" "kirby" {
  name             = "kirby-subnetwork"
  network          = google_compute_network.kirby.id
  ip_cidr_range    = "10.206.0.0/20"
  region           = "us-south1"
  stack_type       = "IPV4_IPV6"
  ipv6_access_type = "EXTERNAL"
  project          = "oceanblue-web"
}

resource "google_compute_network_firewall_policy" "kirby" {
  name    = "kirby-firewall-policy"
  project = "oceanblue-web"
}

# Allow SSH via Google Cloud Console
resource "google_compute_network_firewall_policy_rule" "kirby_allow_iap_ingress" {
  rule_name       = "allow-iap-ingress"
  action          = "allow"
  description     = "Allow Google IAP ingress traffic"
  direction       = "INGRESS"
  disabled        = false
  firewall_policy = google_compute_network_firewall_policy.kirby.id
  priority        = 994
  project         = "oceanblue-web"

  match {
    src_ip_ranges = ["35.235.240.0/20"]

    layer4_configs {
      ip_protocol = "tcp"
      ports       = ["22"]
    }
  }
}

resource "google_compute_network_firewall_policy_rule" "kirby_allow_cloudflare_ingress_ipv4" {
  rule_name       = "allow-cloudflare-ingress-ipv4"
  action          = "allow"
  description     = "Allow Cloudflare ingress traffic IPV4"
  direction       = "INGRESS"
  disabled        = false
  firewall_policy = google_compute_network_firewall_policy.kirby.id
  priority        = 995
  project         = "oceanblue-web"

  match {
    src_ip_ranges = local.cloudflare_ipv4_cidrs

    layer4_configs {
      ip_protocol = "tcp"
      ports       = ["443"]
    }

    layer4_configs {
      ip_protocol = "udp"
      ports       = ["443"]
    }
  }
}

resource "google_compute_network_firewall_policy_rule" "kirby_allow_cloudflare_ingress_ipv6" {
  rule_name       = "allow-cloudflare-ingress-ipv6"
  action          = "allow"
  description     = "Allow Cloudflare ingress traffic IPV6"
  direction       = "INGRESS"
  disabled        = false
  firewall_policy = google_compute_network_firewall_policy.kirby.id
  priority        = 996
  project         = "oceanblue-web"

  match {
    src_ip_ranges = local.cloudflare_ipv6_cidrs

    layer4_configs {
      ip_protocol = "tcp"
      ports       = ["443"]
    }

    layer4_configs {
      ip_protocol = "udp"
      ports       = ["443"]
    }
  }
}

resource "google_compute_network_firewall_policy_rule" "kirby_allow_all_egress_ipv4" {
  rule_name       = "allow-all-egress-ipv4"
  action          = "allow"
  description     = "Allow all egress traffic IPV4"
  direction       = "EGRESS"
  disabled        = false
  firewall_policy = google_compute_network_firewall_policy.kirby.id
  priority        = 997
  project         = "oceanblue-web"

  match {
    dest_ip_ranges = ["0.0.0.0/0"]
    layer4_configs {
      ip_protocol = "all"
    }
  }
}

resource "google_compute_network_firewall_policy_rule" "kirby_allow_all_egress_ipv6" {
  rule_name       = "allow-all-egress-ipv6"
  action          = "allow"
  description     = "Allow all egress traffic IPV6"
  direction       = "EGRESS"
  disabled        = false
  firewall_policy = google_compute_network_firewall_policy.kirby.id
  priority        = 998
  project         = "oceanblue-web"

  match {
    dest_ip_ranges = ["::/0"]
    layer4_configs {
      ip_protocol = "all"
    }
  }
}

resource "google_compute_network_firewall_policy_rule" "kirby_deny_all_ingress_ipv4" {
  rule_name       = "deny-all-ingress-ipv4"
  action          = "deny"
  description     = "Deny all ingress traffic IPV4"
  direction       = "INGRESS"
  disabled        = false
  firewall_policy = google_compute_network_firewall_policy.kirby.id
  priority        = 999
  project         = "oceanblue-web"

  match {
    src_ip_ranges = ["0.0.0.0/0"]
    layer4_configs {
      ip_protocol = "all"
    }
  }
}

resource "google_compute_network_firewall_policy_rule" "kirby_deny_all_ingress_ipv6" {
  rule_name       = "deny-all-ingress-ipv6"
  action          = "deny"
  description     = "Deny all ingress traffic IPV6"
  direction       = "INGRESS"
  disabled        = false
  firewall_policy = google_compute_network_firewall_policy.kirby.id
  priority        = 1000
  project         = "oceanblue-web"

  match {
    src_ip_ranges = ["::/0"]
    layer4_configs {
      ip_protocol = "all"
    }
  }
}

resource "google_compute_network_firewall_policy_association" "kirby" {
  name              = "kirby-association"
  attachment_target = google_compute_network.kirby.id
  firewall_policy   = google_compute_network_firewall_policy.kirby.name
  project           = "oceanblue-web"
}

resource "google_storage_bucket" "kirby_data" {
  name                        = "kirby.george.black"
  location                    = "US-SOUTH1"
  project                     = "oceanblue-web"
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }
}

resource "google_service_account" "kirby" {
  account_id   = "kirby-server"
  display_name = "Kirby Server"
  description  = "Used by Kirby server to access Google Cloud Storage"
  project      = "oceanblue-web"
}

resource "google_project_iam_member" "kirby_storage_access" {
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.kirby.email}"
  project = "oceanblue-web"
}

data "local_file" "kirby_startup" {
  filename = "${path.module}/assets/startup.sh"
}

resource "google_compute_instance" "kirby" {
  name                    = "kirby"
  machine_type            = "e2-micro"
  zone                    = "us-south1-a"
  project                 = "oceanblue-web"
  metadata_startup_script = data.local_file.kirby_startup.content

  boot_disk {
    auto_delete = true

    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/ubuntu-2004-focal-v20240830"
      size  = 10
    }
  }

  network_interface {
    network            = google_compute_network.kirby.name
    subnetwork         = google_compute_subnetwork.kirby.name
    subnetwork_project = "oceanblue-web"
    stack_type         = "IPV4_IPV6"

    # Enables ephemeral IPV4
    access_config {}

    # Enables ephemeral IPV6
    ipv6_access_config {
      network_tier = "PREMIUM"
    }
  }

  service_account {
    email  = google_service_account.kirby.email
    scopes = ["cloud-platform"]
  }

  depends_on = [google_storage_bucket.kirby_data]
}
