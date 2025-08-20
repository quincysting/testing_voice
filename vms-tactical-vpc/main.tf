locals {
  tags = {
    # Management Layer Tags
    o_b_bu      = "networks"     # Business unit
    o_b_pri-own = "alfred lam"   # Primary owner
    o_b_bus-own = "james burden" # Financial owner

    # Application Layer Tags
    o_t_app-plat  = "networks"                 # Business division in MEGA
    o_t_app       = "aws-networks"             # Application name in MEGA
    o_t_env       = "poc"                      # Environment: prd | drp | ppt | gnp | pet | dev | sit | uat | poc
    o_t_app-own   = "thanzeer uchummal chalil" # Current staff in charge
    o_t_tech-own  = "daniel shougum"           # Current staff support
    o_b_cc        = "gk881infra"               # Financial cost centre
    o_s_app-class = "cat2"                     # Cyber App category in MEGA: cat1 | cat2 | cat3 | cat4
    o_b_project   = "aws-networks"             # Project name

    # Resource Layer Tags
    o_s_data-class = "conf_non_pii" # Data classification: secret | conf_pii | conf_non_pii | public
    o_t_app-role   = "inf"          # Resource role: app | web | db | file | inf | eng | others
    o_a_avail      = "24x7"         # Finops Operating hours: 24x7 | 12x5 | 8x5 | spot | until_<YYYYMMDD>
    o_s_sra        = "00642"        # Cyber SRA no
    o_t_dep-mthd   = "iac"          # How resources are managed: iac | hybrid | clickops
    o_t_lifecycle  = "inbuild"      # Current state: inbuild | active | deprecated | retired
  }

  vpc_name = "optus-networks-gnp-vmspoc"
}

data "aws_region" "this" {}

module "vms_tactical" {
  source = "../modules/terraform-aws-optus-networks-vpc"

  vpc_name = local.vpc_name

  vpc_cidr = "172.19.209.0/24"
  vpc_secondary_cidrs = [
    "100.66.0.0/24",
    "100.64.0.0/16", # non-routeable address space for vpc-endpoints
  ]

  subnets = {
    utility-2a = {
      availability_zone = "ap-southeast-2a"
      cidr              = "172.19.209.0/26"
      route_table       = "routeable"
    }

    utility-2b = {
      availability_zone = "ap-southeast-2b"
      cidr              = "172.19.209.64/26"
      route_table       = "routeable"
    }

    worker-2a = {
      availability_zone = "ap-southeast-2a"
      cidr              = "172.19.209.128/27"
      route_table       = "routeable"
    }

    worker-2b = {
      availability_zone = "ap-southeast-2b"
      cidr              = "172.19.209.160/27"
      route_table       = "routeable"
    }

    sbp-sip-2a = {
      availability_zone = "ap-southeast-2a"
      cidr              = "100.66.0.0/27"
      route_table       = "routeable"
    }

    sbp-sip-2b = {
      availability_zone = "ap-southeast-2b"
      cidr              = "100.66.0.32/27"
      route_table       = "routeable"
    }

    voicemail-2a = {
      availability_zone = "ap-southeast-2a"
      cidr              = "100.66.0.64/27"
      route_table       = "routeable"
    }

    voicemail-2b = {
      availability_zone = "ap-southeast-2b"
      cidr              = "100.66.0.96/27"
      route_table       = "routeable"
    }

    imap-2a = {
      availability_zone = "ap-southeast-2a"
      cidr              = "100.66.0.128/28"
      route_table       = "routeable"
    }

    imap-2b = {
      availability_zone = "ap-southeast-2b"
      cidr              = "100.66.0.144/28"
      route_table       = "routeable"
    }

    vpce-2a = {
      availability_zone = "ap-southeast-2a"
      cidr              = "100.64.0.0/24"
    }
  }

  route_tables = {
    routeable = {}
  }

  //enable cloud watch
  enable_flow_log              = true
  flow_log_destination_type    = "cloud-watch-logs"
  flow_log_traffic_type        = "ALL"
  flow_log_retention_days      = 30

  tags = local.tags
}