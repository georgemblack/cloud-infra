terraform {
  backend "gcs" {
    bucket = "terraform.george.black"
    prefix = "web"
  }
}

resource "google_storage_bucket" "assets_staging" {
  name                        = "web-assets-staging.george.black"
  location                    = "US"
  force_destroy               = true
  project                     = "oceanblue-web"
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }
}

resource "google_storage_bucket" "assets" {
  name                        = "web-assets.george.black"
  location                    = "US"
  force_destroy               = true
  project                     = "oceanblue-web"
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }
}

resource "google_storage_bucket" "snapshots" {
  name                        = "web-snapshots.george.black"
  location                    = "US-SOUTH1"
  storage_class               = "ARCHIVE"
  force_destroy               = true
  project                     = "oceanblue-web"
  uniform_bucket_level_access = true

  versioning {
    enabled = false
  }
}

resource "google_storage_bucket" "snapshots_staging" {
  name                        = "web-snapshots-staging.george.black"
  location                    = "US-SOUTH1"
  storage_class               = "ARCHIVE"
  force_destroy               = true
  project                     = "oceanblue-web"
  uniform_bucket_level_access = true

  versioning {
    enabled = false
  }
}

# Service account for Transmit app on the Mac
resource "google_service_account" "transmit" {
  account_id   = "transmit"
  display_name = "Transmit"
  description  = "Used by Transmit for Mac to sync assets to Google Cloud Storage"
  project      = "oceanblue-web"
}

# Enable Transmit to Cloud Storage
resource "google_project_iam_member" "transmit" {
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.transmit.email}"
  project = "oceanblue-web"
}

# Service account for GitHub Codespaces
resource "google_service_account" "codespaces" {
  account_id   = "github-codespaces"
  display_name = "GitHub Codespaces"
  description  = "Used by GitHub Codespaces for development"
  project      = "oceanblue-web"
}

# Enable Codespaces general project access
resource "google_project_iam_member" "codespaces" {
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.codespaces.email}"
  project = "oceanblue-web"
}

# Service account for Web Builder service
resource "google_service_account" "web_builder" {
  account_id   = "web-builder"
  display_name = "Builder"
  description  = "Used by Web Builder Cloud Run service"
  project      = "oceanblue-web"
}

# Enable Web Builder to access secrets
resource "google_project_iam_member" "web_builder_secret_access" {
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.web_builder.email}"
  project = "oceanblue-web"
}

# Enable Web Builder to access assets in Cloud Storage
resource "google_project_iam_member" "web_builder_storage_access" {
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.web_builder.email}"
  project = "oceanblue-web"
}

# Service account for Web API service
resource "google_service_account" "web_api" {
  account_id   = "web-api"
  display_name = "API"
  description  = "Used by Web API Cloud Run service"
  project      = "oceanblue-web"
}

# Enable Web API to access secrets
resource "google_project_iam_member" "web_api_secret_access" {
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.web_api.email}"
  project = "oceanblue-web"
}

# Enable Web API to access data in Cloud Firestore
resource "google_project_iam_member" "web_api_firestore_access" {
  role    = "roles/datastore.user"
  member  = "serviceAccount:${google_service_account.web_api.email}"
  project = "oceanblue-web"
}

# Enable Web API to invoke Web Builder
resource "google_project_iam_member" "web_api_cloud_run_access" {
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.web_api.email}"
  project = "oceanblue-web"
}
