module "vpc" {
  source                  = "terraform-aws-modules/vpc/aws"
  name                    = "durianpay-vpc-test"
  cidr                    = "192.168.0.0/16"
  azs                     = ["ap-southeast-1a"]
  private_subnets         = ["192.168.1.0/24"]
  public_subnets          = ["192.168.11.0/24"]
  enable_nat_gateway      = true
  single_nat_gateway      = true
  one_nat_gateway_per_az  = false
  tags = {
    Terraform     = "true"
    Product       = "durianpay"
    Environment   = "technical-test"
  }
}
