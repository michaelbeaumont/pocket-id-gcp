resource "google_project_iam_member" "run_invoker" {
  project = google_project_service.run.project
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.run.email}"
}

resource "google_secret_manager_secret" "backblaze_key_id" {
  secret_id = "backblaze_key_id"
  project   = google_project_service.secretmanager.project
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "backblaze_key" {
  secret_id = "backblaze_key"
  project   = google_project_service.secretmanager.project
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "repository_password" {
  secret_id = "repository_password"
  project   = google_project_service.secretmanager.project
  replication {
    auto {}
  }
}

data "google_iam_policy" "run_secret" {
  binding {
    role = "roles/secretmanager.secretAccessor"
    members = [
      "serviceAccount:${google_service_account.run.email}",
    ]
  }
}

resource "google_secret_manager_secret_iam_policy" "backblaze_key_id" {
  project     = google_project_service.secretmanager.project
  secret_id   = google_secret_manager_secret.backblaze_key_id.secret_id
  policy_data = data.google_iam_policy.run_secret.policy_data
}

resource "google_secret_manager_secret_iam_policy" "backblaze_key" {
  project     = google_project_service.secretmanager.project
  secret_id   = google_secret_manager_secret.backblaze_key.secret_id
  policy_data = data.google_iam_policy.run_secret.policy_data
}

resource "google_secret_manager_secret_iam_policy" "repository_password" {
  project     = google_project_service.secretmanager.project
  secret_id   = google_secret_manager_secret.repository_password.secret_id
  policy_data = data.google_iam_policy.run_secret.policy_data
}

resource "google_secret_manager_secret_version" "backblaze_key_id" {
  depends_on     = [google_secret_manager_secret_iam_policy.backblaze_key_id]
  secret         = google_secret_manager_secret.backblaze_key_id.id
  secret_data_wo = var.backblaze_key_id
}

resource "google_secret_manager_secret_version" "backblaze_key" {
  depends_on     = [google_secret_manager_secret_iam_policy.backblaze_key]
  secret         = google_secret_manager_secret.backblaze_key.id
  secret_data_wo = var.backblaze_key
}

resource "google_secret_manager_secret_version" "repository_password" {
  depends_on     = [google_secret_manager_secret_iam_policy.repository_password]
  secret         = google_secret_manager_secret.repository_password.id
  secret_data_wo = var.backblaze_repository_password
}

resource "google_cloud_run_v2_job" "backup" {
  project             = google_project_iam_member.run_invoker.project
  name                = "pocket-id-backup"
  location            = var.region
  deletion_protection = false

  template {
    template {
      service_account = google_service_account.run.email

      containers {
        image = "docker.io/restic/restic"
        resources {
          limits = {
            cpu    = "1"
            memory = "512Mi"
          }
        }
        env {
          name = "AWS_ACCESS_KEY_ID"
          value_source {
            secret_key_ref {
              secret  = google_secret_manager_secret_version.backblaze_key_id.secret
              version = "latest"
            }
          }
        }
        env {
          name = "AWS_SECRET_ACCESS_KEY"
          value_source {
            secret_key_ref {
              secret  = google_secret_manager_secret_version.backblaze_key.secret
              version = "latest"
            }
          }
        }
        env {
          name  = "RESTIC_REPOSITORY"
          value = var.backblaze_bucket
        }
        env {
          name  = "RESTIC_PASSWORD_FILE"
          value = "/secrets/repository_password"
        }
        args = ["backup", "/app/data"]
        volume_mounts {
          name       = "data"
          mount_path = "/app/data"
        }
        volume_mounts {
          name       = "repository_password"
          mount_path = "/secrets"
        }
      }

      volumes {
        name = "data"
        gcs {
          bucket = google_storage_bucket.data.name
        }
      }

      volumes {
        name = "repository_password"
        secret {
          secret = google_secret_manager_secret_version.repository_password.secret
        }
      }
    }
  }
}

resource "google_cloud_scheduler_job" "backup" {
  project = google_project_service.cloudscheduler.project
  name    = "pocket-id-backup"
  region  = var.schedule_region

  attempt_deadline = "320s"
  schedule         = "0 */12 * * *"

  retry_config {
    retry_count = 3
  }

  http_target {
    http_method = "POST"
    uri         = "https://${google_cloud_run_v2_job.backup.location}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/${google_project.this.number}/jobs/${google_cloud_run_v2_job.backup.name}:run"

    oauth_token {
      service_account_email = google_service_account.run.email
    }
  }
}
