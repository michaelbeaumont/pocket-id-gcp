resource "google_compute_network" "this" {
  project                 = google_project.this.project_id
  name                    = "pocket-id"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "this" {
  project       = google_project.this.project_id
  region        = var.region
  network       = google_compute_network.this.id
  ip_cidr_range = "10.0.0.0/22"

  name = "pocket-id"
}
