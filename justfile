apply:
    terraform apply

destroy:
    terraform state rm google_compute_subnetwork.this google_compute_network.this
    terraform destroy
