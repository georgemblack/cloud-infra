variable "project" {
  description = "The Google Cloud project to deploy to."
  type        = string
  default     = ""
}

variable "bucket_name" {
  description = "Name of bucket for web assets."
  type        = string
  default     = ""
}
