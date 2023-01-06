terraform {
  backend "gcs" {
    bucket = "terraform.george.black"
    prefix = "test-project"
  }
}

resource "random_id" "placeholder" {
  byte_length = 8
}
