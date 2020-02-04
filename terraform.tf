
#Need to run terraform init with:
# -backend-config="credentials=/path/to/service-account.js"
#to provide credentials for Google Storage
terraform {
  backend "gcs" {
    bucket = "demo-environments-state"
    prefix = "terraform/mcm-icp"
  }
}