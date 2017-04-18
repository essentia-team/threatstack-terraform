// Setup a default CloudTrail trail.

//Variables
variable "aws_account" {
  type = "string"
  description = "Used for naming S3 bucket in tf_example_aws_s3"
}

variable "aws_profile" {
  type = "string"
  description = "Used to configure AWS provider."
}

variable "aws_region" {
  type = "string"
  description = "Used for finding root state in tf_example_aws_s3"
}

variable "aws_cloudtrail_name" {
  type = "string"
  description = "Name of CloudTrail trail."
  default = "ThreatStackIntegration"
}

variable "aws_sns_topic_name" {
  type = "string"
  description = "Name of SNS topic."
  default = "ThreatStackIntegration"
}

variable "aws_sns_topic_display_name" {
  type = "string"
  description = "SNS topic display name"
  default = "Threat Stack integration topic."
}

variable "s3_bucket_name" {
  type = "string"
  description = "S3 Bucket for logs"
  default = "threatstack-integration"
}

variable "s3_bucket_prefix" {
  type = "string"
  description = "S3 prefix path for logs"
  default = "/"
}

variable "enable_logging" {
  description = "Enable logging, set to 'false' to pause logging."
  default = true
}

variable "enable_log_file_validation" {
  description = "Create signed digest file to validated contents of logs."
  default = true
}

variable "include_global_service_events" {
  description = "include evnets from global services such as IAM."
  default = true
}

variable "is_multi_region_trail" {
  description = "Whether the trail is created in all regions or just the current region."
  default = true
}


// Backend
# NOTE: Backends cannot contain interpolations at this time. :-|
terraform {
  backend "s3" {
    encrypt = "true"
    bucket  = "ts-demo-dev-terraform"
    key     = "aws_cloudtrail_threatstack.tfstate"
    region  = "us-east-1"
  }
}


// AWS provider
provider "aws" {
  profile = "${var.aws_profile}"
  region  = "${var.aws_region}"
}


// Data
data "terraform_remote_state" "root" {
  backend = "s3"
  config = {
    bucket  = "${var.aws_account}-terraform"
    key     = "root.tfstate"
    region  = "${var.aws_region}"
  }
}

data "template_file" "aws_sns_topic_policy" {
  template = "${file("${path.module}/aws_sns_topic_policy.tpl")}"
}

// Resources
module "aws_cloudtrail" {
  source                        = "../tf_threatstack_aws_cloudtrail"
  aws_cloudtrail_name           = "${var.aws_cloudtrail_name}"
  s3_bucket_name                = "${var.s3_bucket_name}"
  enable_logging                = "${var.enable_logging}"
  enable_log_file_validation    = "${var.enable_log_file_validation}"
  include_global_service_events = "${var.include_global_service_events}"
  is_multi_region_trail         = "${var.enable_log_file_validation}"
  aws_account                   = "${var.aws_account}"
  aws_account_id                = "${data.terraform_remote_state.root.aws_account_id}"
  aws_region                    = "${var.aws_region}"
}

resource "aws_sns_topic" "sns" {
  name = "${var.aws_sns_topic_name}"
  display_name = "${var.aws_sns_topic_display_name}"
}

resource "aws_sns_topic_policy" "sns" {
  arn = "${aws_sns_topic.sns.arn}"
  policy = "${data.template_file.aws_sns_topic_policy.rendered}"
}



// Outputs
output "cloudtrail_id" {
  value = "${module.aws_cloudtrail.cloudtrail_id}"
}

output "cloudtrail_home_region" {
  value = "${module.aws_cloudtrail.cloudtrail_home_region}"
}

output "cloudtrail_arn" {
  value = "${module.aws_cloudtrail.cloudtrail_arn}"
}

output "iam_role_cloudtrail_arn" {
  value = "${module.aws_cloudtrail.iam_role_cloudtrail_arn}"
}

output "cloudwatch_log_group_arn" {
  value = "${module.aws_cloudtrail.cloudwatch_log_group_arn}"
}

output "s3_bucket_id" {
  value = "${module.aws_cloudtrail.s3_bucket_id}"
}

output "s3_bucket_arn" {
  value = "${module.aws_cloudtrail.s3_bucket_arn}"
}

output "sns_topic_arn" {
  value = "${aws_sns_topic.sns.arn}"
}

