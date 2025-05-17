resource "google_artifact_registry_repository" "ghcr" {
  project       = google_project_service.artifactregistry.project
  location      = var.region
  repository_id = "ghcr"
  format        = "DOCKER"
  mode          = "REMOTE_REPOSITORY"
  remote_repository_config {
    disable_upstream_validation = true
    common_repository {
      uri = "https://ghcr.io"
    }
  }

  cleanup_policies {
    id     = "delete-all"
    action = "DELETE"
    condition {
    }
  }
  cleanup_policies {
    id     = "keep-1"
    action = "KEEP"
    most_recent_versions {
      keep_count = 1
    }
  }
}

locals {
  registry_uri = "${google_artifact_registry_repository.ghcr.location}-docker.pkg.dev/${google_project.this.project_id}/${google_artifact_registry_repository.ghcr.repository_id}"
}

resource "google_artifact_registry_repository_iam_member" "this" {
  project    = google_artifact_registry_repository.ghcr.project
  location   = var.region
  repository = google_artifact_registry_repository.ghcr.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.run.email}"
}
