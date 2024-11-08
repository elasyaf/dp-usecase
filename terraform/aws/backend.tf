terraform {
  backend "s3" {
    profile = "default"
    bucket  = "dptest-tfbucket"
    key     = "experiments/durianpay-net.tfstate"
    region  = "ap-southeast-1"
  }
}
