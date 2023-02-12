terraform {
  backend "gcs" {
    bucket = "terraform.george.black"
    prefix = "web"
  }
}

resource "google_storage_bucket" "assets" {
  name                        = var.bucket_name
  location                    = "US"
  force_destroy               = true
  project                     = var.project
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }
}

resource "google_service_account" "transmit" {
  account_id   = "transmit"
  display_name = "Transmit"
  description  = "Used by Transmit for Mac to sync assets to Google Cloud Storage"
  project      = var.project
}

resource "google_project_iam_member" "transmit" {
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.transmit.email}"
  project = var.project
}

resource "google_service_account" "codespaces" {
  account_id   = "github-codespaces"
  display_name = "GitHub Codespaces"
  description  = "Used by GitHub Codespaces for development"
  project      = var.project
}

resource "google_project_iam_member" "codespaces" {
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.codespaces.email}"
  project = var.project
}
