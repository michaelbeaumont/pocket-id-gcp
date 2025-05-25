resource "google_storage_bucket" "static" {
  project       = google_project.this.project_id
  name          = "pocket-id-static-public"
  location      = "EU"
  force_destroy = true

  uniform_bucket_level_access = true
}

data "google_iam_policy" "public_static" {
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
    role = "roles/storage.legacyObjectReader"
    members = [
      "allUsers",
    ]
  }
}

resource "google_storage_bucket_iam_policy" "public_static" {
  bucket      = google_storage_bucket.static.name
  policy_data = data.google_iam_policy.public_static.policy_data
}

resource "google_storage_bucket_object" "not_found" {
  name   = "404.html"
  bucket = google_storage_bucket.static.id

  # We can't set `content = ""` due to what is obviously a provider bug
  # and we don't want _any_ content so that the browser 404 is shown
  source = "${path.module}/404.html"
}

resource "google_storage_bucket_object" "webfinger" {
  name   = ".well-known/webfinger"
  bucket = google_storage_bucket.static.id

  content      = <<EOT
{
  "subject": "acct:${var.webfinger_acct}",
  "links": [
    {
      "rel": "http://openid.net/specs/connect/1.0/issuer",
      "href": "https://${local.issuer_fqdn}"
    }
  ]
}
EOT
  content_type = "application/json"
}
