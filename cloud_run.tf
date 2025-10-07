resource "google_service_account" "run" {
  account_id   = "pocket-id-run"
  project      = google_project.this.project_id
  display_name = "Pocket ID Cloud Run"
}

resource "google_storage_bucket" "data" {
  project       = google_project.this.project_id
  name          = "pocket-id-data"
  location      = "EU"
  force_destroy = true

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
}

data "google_iam_policy" "data" {
  binding {
    role = "roles/storage.legacyBucketOwner"
    members = [
      "projectOwner:${google_project.this.project_id}",
    ]
  }
  binding {
    role = "roles/storage.legacyObjectOwner"
    members = [
      "projectOwner:${google_project.this.project_id}",
    ]
  }
  binding {
    role = "roles/storage.objectUser"
    members = [
      "serviceAccount:${google_service_account.run.email}",
    ]
  }
}

resource "google_storage_bucket_iam_policy" "data" {
  bucket      = google_storage_bucket.data.name
  policy_data = data.google_iam_policy.data.policy_data
}

resource "google_secret_manager_secret" "private_key" {
  secret_id = "pocket-id-private-key"
  project   = google_project.this.project_id
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_iam_member" "private_key" {
  project   = google_project_service.secretmanager.project
  secret_id = google_secret_manager_secret.private_key.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.run.email}"
}

locals {
  jwt_private_key_file = "${path.module}/jwt_private_key.json"
}

resource "google_secret_manager_secret_version" "private_key" {
  secret = google_secret_manager_secret_iam_member.private_key.secret_id

  # It seems like if there are no versions, some attributes are null
  # hopefully this actually works
  secret_data_wo         = fileexists(local.jwt_private_key_file) || google_secret_manager_secret.private_key.version_aliases == null ? file(local.jwt_private_key_file) : ""
  secret_data_wo_version = 0
}

locals {
  pocket_id_version = "v1.13.1-distroless"
}

resource "google_cloud_run_v2_service" "this" {
  # for default_uri_disabled
  provider = google-beta

  depends_on          = [google_project_service.run]
  project             = google_project.this.project_id
  name                = "pocket-id"
  location            = var.region
  deletion_protection = false

  ingress              = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
  invoker_iam_disabled = true

  default_uri_disabled = true

  template {
    service_account = google_service_account.run.email
    scaling {
      min_instance_count = 0
      max_instance_count = 1
    }

    containers {
      name  = "pocket-id"
      image = "${local.registry_uri}/pocket-id/pocket-id:${local.pocket_id_version}"
      ports {
        container_port = 8080
      }
      resources {
        limits = {
          cpu    = "1000m"
          memory = "512Mi"
        }
        cpu_idle = true
      }
      env {
        name  = "APP_URL"
        value = "https://${local.issuer_fqdn}"
      }
      env {
        name  = "KEYS_PATH"
        value = "/app/keys"
      }
      env {
        name  = "ANALYTICS_DISABLED"
        value = "true"
      }
      dynamic "env" {
        for_each = var.additional_env
        content {
          name  = env.key
          value = env.value
        }
      }
      volume_mounts {
        name       = "data"
        mount_path = "/app/data"
      }
      volume_mounts {
        name       = "private_key"
        mount_path = "/app/keys"
      }

      # These values are pretty arbitrary
      # And it might not be enough for the first run with GCS
      startup_probe {
        failure_threshold     = 10
        initial_delay_seconds = 5
        timeout_seconds       = 5
        period_seconds        = 10

        http_get {
          path = "/healthz"
        }
      }
      liveness_probe {
        failure_threshold     = 2
        initial_delay_seconds = 0
        timeout_seconds       = 5
        period_seconds        = 90

        http_get {
          path = "/healthz"
        }
      }
    }

    volumes {
      name = "data"
      gcs {
        bucket = google_storage_bucket.data.name
      }
    }
    volumes {
      name = "private_key"
      secret {
        secret = google_secret_manager_secret_version.private_key.secret
        items {
          path    = "jwt_private_key.json"
          version = "latest"
        }
      }
    }
  }
}
