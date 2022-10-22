# VPC Input Variables

# VPC Name
variable "vpc_name" {
  description = "VPC Name"
  type = string 
  default = "myvpc"
}

# VPC CIDR Block
variable "vpc_cidr_block" {
  description = "VPC CIDR Block"
  type = string 
  default = "10.0.0.0/16"
}

# VPC Availability Zones
variable "vpc_availability_zones" {
  description = "VPC Availability Zones"
  type = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

# VPC Public Subnets
variable "vpc_public_subnets" {
  description = "VPC Public Subnets"
  type = list(string)
  default = ["10.0.101.0/24", "10.0.102.0/24"]
}

# VPC Private Subnets
variable "vpc_private_subnets" {
  description = "VPC Private Subnets"
  type = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

# VPC Database Subnets
variable "vpc_database_subnets" {
  description = "VPC Database Subnets"
  type = list(string)
  default = ["10.0.151.0/24", "10.0.152.0/24"]
}

# VPC Create Database Subnet Group (True / False)
#variable "vpc_create_database_subnet_group" {
#  description = "VPC Create Database Subnet Group"
#  type = bool
#  default = true 
#}

# VPC Create Database Subnet Route Table (True or False)
#variable "vpc_create_database_subnet_route_table" {
#  description = "VPC Create Database Subnet Route Table"
#  type = bool
#  default = true   
#}

  
# VPC Enable NAT Gateway (True or False) 
variable "vpc_enable_nat_gateway" {
  description = "Enable NAT Gateways for Private Subnets Outbound Communication"
  type = bool
  default = true  
}

# VPC Single NAT Gateway (True or False)
variable "vpc_single_nat_gateway" {
  description = "Enable only single NAT Gateway in one Availability Zone to save costs during our demos"
  type = bool
  default = true
}

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

variable "create_bucket" {
  default     = true
  description = "Create S3 bucket to receive VPC flow logs? `vpcflowlog_bucket` must be specified if this is false."
  type        = bool
}

variable "create_kms_key" {
  default     = true
  description = "Create KMS key to encrypt flow logs? `vpcflowlog_kms_key` must be specified if this is false."
  type        = bool
}

variable "kms_alias" {
  default     = "vpcflowlog_key"
  description = "KMS Key Alias for VPC flow log KMS key"
  type        = string
}

variable "log_to_cloudwatch" {
  default     = true
  description = "Should VPC flow logs be written to CloudWatch Logs"
  type        = bool
}

variable "log_to_s3" {
  default     = true
  description = "Should VPC flow logs be written to S3"
  type        = bool
}

variable "logging_bucket" {
  default     = ""
  description = "S3 bucket to send request logs to the VPC flow log bucket to (required if `create_bucket` is true)"
  type        = string
}

variable "region" {
  description = "Region VPC flow logs will be sent to"
  type        = string
}

variable "tags" {
  default     = {}
  description = "Tags to include on resources that support it"
  type        = map(string)
}

variable "vpc_ids" {
  description = "List of VPCs to enable flow logging for"
  type        = list(string)
}

variable "vpcflowlog_bucket" {
  default     = ""
  description = "S3 bucket to receive VPC flow logs (required it `create_bucket` is false)"
}

variable "vpcflowlog_kms_key" {
  default     = ""
  description = "KMS key to use for VPC flow log encryption (required it `create_kms_key` is false)"
}





