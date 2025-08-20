# #Optus Tactical VPC and Subnets Configuration
# data "aws_vpc" "optus-tactical-vpc" {
#   id = "vpc-0d1467ee215ff5c37"
# }

#Uncomment lines above to use a Optus VPC
/*
|  subnet-031d0e1b69a135a2f|  vpc-0d1467ee215ff5c37 |  172.19.209.128/27 |  ap-southeast-2a |  available |  False |  27  |  optus-networks-gnp-vmspoc-worker-2a      |

|  subnet-01f371b1ca6c2b5b9|  vpc-0d1467ee215ff5c37 |  172.19.209.160/27 |  ap-southeast-2b |  available |  False |  27  |  optus-networks-gnp-vmspoc-worker-2b      |

|  subnet-0364ace290f0abd0e|  vpc-0d1467ee215ff5c37 |  100.66.0.0/27     |  ap-southeast-2a |  available |  False |  27  |  optus-networks-gnp-vmspoc-sbp-sip-2a     |

|  subnet-0fe64a9dad23fc411|  vpc-0d1467ee215ff5c37 |  100.66.0.32/27    |  ap-southeast-2b |  available |  False |  27  |  optus-networks-gnp-vmspoc-sbp-sip-2b     |

|  subnet-0f3c678eeda1eccf6|  vpc-0d1467ee215ff5c37 |  100.66.0.96/27    |  ap-southeast-2b |  available |  False |  27  |  optus-networks-gnp-vmspoc-voicemail-2b   |

|  subnet-02e98f9571d3c80bb|  vpc-0d1467ee215ff5c37 |  100.66.0.64/27    |  ap-southeast-2a |  available |  False |  27  |  optus-networks-gnp-vmspoc-voicemail-2a   |

|  subnet-094b540ceb242d3e3|  vpc-0d1467ee215ff5c37 |  100.66.0.128/28   |  ap-southeast-2a |  available |  False |  11  |  optus-networks-gnp-vmspoc-imap-2a        |

|  subnet-0fc9c67feb60f11f9|  vpc-0d1467ee215ff5c37 |  100.66.0.144/28   |  ap-southeast-2b |  available |  False |  11  |  optus-networks-gnp-vmspoc-imap-2b        |

|  subnet-08e812930ead6e00d|  vpc-0d1467ee215ff5c37 |  172.19.209.0/26   |  ap-southeast-2a |  available |  False |  58  |  optus-networks-gnp-vmspoc-utility-2a     |

|  subnet-08af6b4eb1741cdcc|  vpc-0d1467ee215ff5c37 |  172.19.209.64/26  |  ap-southeast-2b |  available |  False |  59  |  optus-networks-gnp-vmspoc-utility-2b     |

+--------------------------+------------------------+--------------------+------------------+------------+--------+------+-------------------------------------------+

 

---------------------------------------------------------------------------

|                              DescribeVpcs                               |

+---------------------------+-------------------+-------------------------+

|           Name            |    PrimaryCIDR    |          VpcId          |

+---------------------------+-------------------+-------------------------+

|  optus-networks-gnp-vmspoc|  172.19.209.0/24  |  vpc-0d1467ee215ff5c37  |

+---------------------------+-------------------+-------------------------+

||                           CIDRAssociations                            ||

|+----------------------------------------+------------------------------+|

||  172.19.209.0/24                    |  associated                  ||

||  100.66.0.0/24                         |  associated                  ||

*/
# data "aws_subnets" "tactical_all_subnets" {
#   filter {
#     name   = "vpc-id"
#     values = [data.aws_vpc.optus-tactical-vpc.id]
#   }
# }

# locals {
#   worker_subnets = [
#     for subnet in data.aws_subnet.filtered :
#     subnet.id if can(regex("(?i)worker", lookup(subnet.tags, "Name", "")))
#   ]
#   sip_subnets = [
#     for subnet in data.aws_subnet.filtered :
#     subnet.id if can(regex("(?i)sip", lookup(subnet.tags, "Name", "")))
#   ]
#   voicemail_subnets = [
#     for subnet in data.aws_subnet.filtered :
#     subnet.id if can(regex("(?i)voicemail", lookup(subnet.tags, "Name", "")))
#   ]
#   imap_subnets = [
#     for subnet in data.aws_subnet.filtered :
#     subnet.id if can(regex("(?i)imap", lookup(subnet.tags, "Name", "")))
#   ]
#   utility_subnets = [
#     for subnet in data.aws_subnet.filtered :
#     subnet.id if can(regex("(?i)utility", lookup(subnet.tags, "Name", "")))
#   ]

#   ##################################2a-Subnets########################################
#   worker_2a_subnets = [
#     for subnet in data.aws_subnet.filtered :
#     subnet.id if can(regex("(?i)worker-2a", lookup(subnet.tags, "Name", "")))
#   ]
#   sip_2a_subnets = [
#     for subnet in data.aws_subnet.filtered :
#     subnet.id if can(regex("(?i)sip-2a", lookup(subnet.tags, "Name", "")))
#   ]
#   voicemail_2a_subnets = [
#     for subnet in data.aws_subnet.filtered :
#     subnet.id if can(regex("(?i)voicemail-2a", lookup(subnet.tags, "Name", "")))
#   ]
#   imap_2a_subnets = [
#     for subnet in data.aws_subnet.filtered :
#     subnet.id if can(regex("(?i)imap-2a", lookup(subnet.tags, "Name", "")))
#   ]
#   utility_2a_subnets = [
#     for subnet in data.aws_subnet.filtered :
#     subnet.id if can(regex("(?i)utility-2a", lookup(subnet.tags, "Name", "")))
#   ]

#   ##################################2b-Subnets########################################
#   worker_2b_subnets = [
#     for subnet in data.aws_subnet.filtered :
#     subnet.id if can(regex("(?i)worker-2b", lookup(subnet.tags, "Name", "")))
#   ]
#   sip_2b_subnets = [
#     for subnet in data.aws_subnet.filtered :
#     subnet.id if can(regex("(?i)sip-2b", lookup(subnet.tags, "Name", "")))
#   ]
#   voicemail_2b_subnets = [
#     for subnet in data.aws_subnet.filtered :
#     subnet.id if can(regex("(?i)voicemail-2b", lookup(subnet.tags, "Name", "")))
#   ]
#   imap_2b_subnets = [
#     for subnet in data.aws_subnet.filtered :
#     subnet.id if can(regex("(?i)imap-2b", lookup(subnet.tags, "Name", "")))
#   ]
#   utility_2b_subnets = [
#     for subnet in data.aws_subnet.filtered :
#     subnet.id if can(regex("(?i)utility-2b", lookup(subnet.tags, "Name", "")))
#   ]

#   ##########################################################################
# }

# voicemail_admin_dashboard_subnets = local.voicemail_subnets
# imap_subnets = local.imap_subnets
# sbc_fs_subnets = local.sip_subnets
# worker_subnets = local.worker_subnets
# utility_subnets = local.utility_subnets

#Norwood Lab Subnets
# variable "voicemail_admin_dashboard_subnets" {
#   description = "List of subnet IDs for the Voicemail service"
#   type        = list(string)
#   default     = ["subnet-0720ec03ad90416c3", "subnet-0884a63641d24170f"] # Norwood Lab
# }

# variable "imap_subnets" {
#   description = "List of subnet IDs for the IMAP service"
#   type        = list(string)
#   default = ["subnet-0dd3ae5e66ab68ad6", "subnet-04cae304eef694a1c"] # Norwood Lab
# }

# variable "sbc_fs_subnets" {
#   description = "List of subnet IDs for the Kamailio/SBC service"
#   type        = list(string)
#   default     = ["subnet-06e973afc15d07937", "subnet-0cb1299ddd156c5c8"]
# }

# variable "worker_subnets" {
#   description = "List of subnets for the service"
#   type        = list(string)
#   default     = ["subnet-0f3312b3c67f5540c", "subnet-0fd7ee0ab0d8798ea"]
# }

# #Utility Subnet for ALB and DB?
# variable "utility_subnets" { 
#   description = "List of subnets for the service"
#   type        = list(string)
#   default     = ["subnet-0f3312b3c67f5540c", "subnet-0fd7ee0ab0d8798ea"]
# }

# variable "alb_subnets" {
#   #default = ["subnet-06e7470e43d97cbc0", "subnet-04c53e37b36d59ed6"]
#   default = ["subnet-0e42ed580f3069fae", "subnet-0f26eace80a2d48df"] #public subnets
# }