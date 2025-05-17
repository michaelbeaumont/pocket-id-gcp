# `pocket-id` on GCP

This is a terraform configuration to fully automatically provision and run `pocket-id`
on GCP and Cloudflare as well as periodically backup to Backblaze. It also
serves a webfinger document that some OIDC RPs require.

It uses:

- Cloud Run for running `pocket-id` and the backup to avoid a VM
- Cloud Storage mounts so we can use sqlite and avoid SQL
- Cloud Scheduler to schedule the backup
- Application Load Balancers to handle traffic
- Artifact registry to pull ghcr.io images
- Buckets to handle webfinger

## Prerequisites

- GCP billing account
- Cloudflare zone and token
- Backblaze bucket and application key

## TODO

- Optionally restore from Backblaze
