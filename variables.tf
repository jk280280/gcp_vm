variable "project_id" {
  description = "Google Cloud project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "us-central1-b"
}

variable "machine_type" {
  description = "Machine type for the instance"
  type        = string
  default     = "e2-small"
}

variable "subnetwork" {
  description = "Subnetwork name"
  type        = string
}

variable "service_account_email" {
  description = "Service account email for the instance"
  type        = string
}

variable "instance_name" {
  description = "Name of the Compute instance"
  type        = string
  default     = "harness-delegate"
}
