output "service-account-subject" {
  description = "Identity of the service account used for cloud run"
  value = google_service_account.run.unique_id
}
