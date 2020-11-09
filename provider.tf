provider "aws" {
  alias   = "threatstack"
  version = "~> 3.0,!= 3.14.0"
  region  = "eu-west-1"
}