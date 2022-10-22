###############################################################################
# VPC Creation
###############################################################################

# Create VPC Terraform Module
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  #version = "2.78.0"
  version = "3.0.0"

  # VPC Basic Details
  #name = "${var.vpc_name}"
  cidr = var.vpc_cidr_block
  azs             = var.vpc_availability_zones
  #name = "Network-Prod-E1-Public-SNET"
  public_subnets  = var.vpc_public_subnets
  #name = "Network-Prod-E1-Private-SNET"
  private_subnets = var.vpc_private_subnets  

  # Database Subnets
  #database_subnets = var.vpc_database_subnets
  #create_database_subnet_group = var.vpc_create_database_subnet_group
  #create_database_subnet_route_table = var.vpc_create_database_subnet_route_table
  # create_database_internet_gateway_route = true
  # create_database_nat_gateway_route = true
  
  # NAT Gateways - Outbound Communication
  enable_nat_gateway = var.vpc_enable_nat_gateway 
  single_nat_gateway = var.vpc_single_nat_gateway

  # VPC DNS Parameters
  enable_dns_hostnames = true
  enable_dns_support   = true


  tags = local.common_tags
  vpc_tags = local.common_tags

  # Additional Tags to Subnets
  public_subnet_tags = {
    Type = "Public Subnets"
  }
  private_subnet_tags = {
    Type = "Private Subnets"
  }  
  database_subnet_tags = {
    Type = "Private Database Subnets"
  }
}

###################################################################################
# Security Group Public
###################################################################################
# AWS EC2 Security Group Terraform Module
# Security Group for Public Subnet
module "public_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  #version = "3.18.0"
  version = "4.0.0"

  #name = "public-sg"  
  name = "Network-Prod-E1-Public-SG"
  description = "Security Group with SSH port open for everybody (IPv4 CIDR), egress ports are all world open"
  vpc_id = module.vpc.vpc_id
  # Ingress Rules & CIDR Blocks
  ingress_rules = ["ssh-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]
  # Egress Rule - all-all open
  egress_rules = ["all-all"]
  tags = local.common_tags
}

#####################################################################################
# Security Group Private 
#####################################################################################
# AWS EC2 Security Group Terraform Module
# Security Group for Private Subnet
module "private_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  #version = "3.18.0"
  version = "4.0.0"
  
  #name = "private-sg"
  name = "Network-Prod-E1-Private-SG"  
  description = "Security Group with HTTP & SSH port open for entire VPC Block (IPv4 CIDR), egress ports are all world open"
  vpc_id = module.vpc.vpc_id
  # Ingress Rules & CIDR Blocks
  ingress_rules = ["ssh-tcp", "http-80-tcp", "http-8080-tcp"]
  ingress_cidr_blocks = [module.vpc.vpc_cidr_block]
  # Egress Rule - all-all open
  egress_rules = ["all-all"]
  tags = local.common_tags
}

######################################################################################
# Security Group Load Balancer
######################################################################################
# Security Group for Public Load Balancer
module "loadbalancer_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  #version = "3.18.0"
  version = "4.0.0"

  #name = "Network-Prod-E1-LB-SG"
  name = "Network-Prod-E1-LB-SG"  
  description = "Security Group with HTTP open for entire Internet (IPv4 CIDR), egress ports are all world open"
  vpc_id = module.vpc.vpc_id
  # Ingress Rules & CIDR Blocks
  ingress_rules = ["http-80-tcp", "https-443-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]
  # Egress Rule - all-all open
  egress_rules = ["all-all"]
  tags = local.common_tags

  # Open to CIDRs blocks (rule or from_port+to_port+protocol+description)
  ingress_with_cidr_blocks = [
    {
      from_port   = 81
      to_port     = 81
      protocol    = 6
      description = "Allow Port 81 from internet"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
}

######################################################################################
# Route 53
#######################################################################################
resource "aws_route53_zone" "flink_aws" {
  name = "flinkaws.com"

  tags = {
    Environment = "core"
  }
}

resource "aws_route53_record" "nameservers" {
  allow_overwrite = true
  name            = "flinkaws.com"
  ttl             = 3600
  type            = "NS"
  zone_id         = aws_route53_zone.flink_aws.zone_id

  records = aws_route53_zone.flink_aws.name_servers
}

#######################################################################################
# Transit Gateway
#######################################################################################
resource "aws_ec2_transit_gateway" "master-tgw" {
  description                     = "TGW with auto accept shared for prod, dev and shared environments"
  amazon_side_asn                 = 64512
  auto_accept_shared_attachments  = "enable"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
  dns_support                     = "enable"
  vpn_ecmp_support                = "enable"
  
  tags = {
    Name = "Network-Prod-E1-TGW"
  }
 }

resource "aws_ram_resource_share" "main" {
  name                      = "Network-Prod-E1-TGW-RAM"
  allow_external_principals = false

  tags = {
    Name = "Network-Prod-E1-TGW-RAM"
  }
}

########################################################################################
# Cloud Watch
########################################################################################
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "Network-Prod-E1-CW"
  
  dashboard_body = <<EOF
{
  "widgets": [
    {
      "type": "metric",
      "x": 8,
      "y": 0,
      "width": 8,
      "height": 6,
      "properties": {
        "metrics": [
          [
            "AWS/EC2",
            "NetworkIn"
          ]
        ],
        "period": 60,
        "stat": "Maximum",
        "region": "us-east-1",
        "title": "Network In"
      }
    },
    {
      "type": "metric",
      "x": 16,
      "y": 0,
      "width": 8,
      "height": 6,
      "properties": {
        "metrics": [
          [
            "AWS/EC2",
            "NetworkOut"
          ]
        ],
        "period": 60,
        "stat": "Maximum",
        "region": "us-east-1",
        "title": "Network Out"
      }
    },
    {
      "type": "metric",
      "x": 8,
      "y": 12,
      "width": 8,
      "height": 6,
      "properties": {
        "metrics": [
          [
            "AWS/TransitGateway",
            "BytesDropCountBlackhole"
          ],
          [
             "AWS/TransitGateway",
            "BytesDropCountNoRoute"
          ],
          [
            "AWS/TransitGateway",
            "BytesIn"
          ],
          [
            "AWS/TransitGateway",
            "BytesOut"
          ]
        ],
        "period": 60,
        "stat": "Maximum",
        "region": "us-east-1",
        "title": "Transit Gateway|Main Stats"
      }
    },
    {
      "type": "metric",
      "x": 16,
      "y": 12,
      "width": 8,
      "height": 6,
      "properties": {
        "metrics": [
          [
            "AWS/VPN",
            "TunnelState"
          ],
          [
             "AWS/VPN",
            "TunnelDataIn"
          ],
          [
            "AWS/VPN",
            "TunnelDataOut"
          ]
        ],
        "period": 60,
        "stat": "Maximum",
        "region": "us-east-1",
        "title": "VPN|Main Stats"
      }
    }
  ]    
}
EOF

}
##########################################################################################
# VPC Flow Logs
##########################################################################################
data "aws_partition" "current" {
}

locals {
  bucket     = var.create_bucket ? aws_s3_bucket.this[0].id : var.vpcflowlog_bucket
  kms_key_id = var.create_kms_key ? aws_kms_key.this[0].arn : var.vpcflowlog_kms_key
  partition  = data.aws_partition.current.partition
}

resource "aws_cloudwatch_log_group" "this" {
  count             = var.log_to_cloudwatch ? 1 : 0
  name_prefix       = "vpcflowlog"
  kms_key_id        = local.kms_key_id
  retention_in_days = 90
  tags              = var.tags
}

data "aws_iam_policy_document" "assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name_prefix        = "vpcflowlog-role"
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

data "aws_iam_policy_document" "this" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogDelivery",
      "logs:DeleteLogDelivery"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "this" {
  name_prefix = "vpcflowlog-"
  policy      = data.aws_iam_policy_document.this.json
}

resource "aws_iam_role_policy_attachment" "vpcflowlog-attach-localconfig-policy" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}

resource "aws_flow_log" "cloudwatch" {
  count           = var.log_to_cloudwatch ? length(var.vpc_ids) : 0
  iam_role_arn    = aws_iam_role.this.arn
  log_destination = aws_cloudwatch_log_group.this[0].arn
  traffic_type    = "ALL"
  vpc_id          = var.vpc_ids[count.index]
}

resource "aws_flow_log" "s3" {
  count                = var.log_to_s3 ? length(var.vpc_ids) : 0
  log_destination      = "arn:${local.partition}:s3:::${local.bucket}"
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = var.vpc_ids[count.index]
}



