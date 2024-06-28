terraform {
  backend "s3" {
    bucket = "automatiq-hubble-tf-state"
    key    = "terraform/examples/aws-ec2-example-test"
    region = "us-east-1"
  }
}