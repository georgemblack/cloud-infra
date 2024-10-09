terraform {
  backend "gcs" {
    bucket = "terraform.george.black"
    prefix = "kirby"
  }
}
