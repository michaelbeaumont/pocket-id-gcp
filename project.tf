resource "random_string" "id_suffix" {
  length  = 6
  lower   = false
  upper   = false
  special = false
}

data "google_billing_account" "account" {
  billing_account = var.gcp_billing_account
  open            = true
}

resource "google_project" "this" {
  billing_account = data.google_billing_account.account.id
  deletion_policy = "DELETE"

  name                = "Pocket ID"
  project_id          = "pocket-id-${random_string.id_suffix.result}"
  auto_create_network = false
}

resource "google_project_service" "servicenetworking" {
  project = google_project.this.project_id
  service = "servicenetworking.googleapis.com"

  disable_dependent_services = true
  disable_on_destroy         = false
}

resource "google_project_service" "secretmanager" {
  project = google_project.this.project_id
  service = "secretmanager.googleapis.com"

  disable_dependent_services = true
  disable_on_destroy         = false
}

resource "google_project_service" "run" {
  project = google_project.this.project_id
  service = "run.googleapis.com"

  disable_dependent_services = true
  disable_on_destroy         = false
}

resource "google_project_service" "cloudscheduler" {
  project = google_project.this.project_id
  service = "cloudscheduler.googleapis.com"

  disable_dependent_services = true
  disable_on_destroy         = false
}

resource "google_project_service" "artifactregistry" {
  project = google_project.this.project_id
  service = "artifactregistry.googleapis.com"

  disable_dependent_services = true
  disable_on_destroy         = false
}
