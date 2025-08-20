# aws-ntwk-svc-lab Tactical VMS VPC

Scratch code to provision tactical VPC environment.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.8 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.46 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.46 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_bastion_instance"></a> [bastion\_instance](#module\_bastion\_instance) | git::https://optus.gitlab-dedicated.com/Optus/GroupIT/TechFoundations/CDOT/terraform-aws-optus-ec2-instance | v1.1.0 |
| <a name="module_bastion_sg"></a> [bastion\_sg](#module\_bastion\_sg) | git::https://optus.gitlab-dedicated.com/Optus/GroupIT/TechFoundations/CDOT/terraform-aws-optus-security-group.git | v1.0.1 |
| <a name="module_vms_tactical"></a> [vms\_tactical](#module\_vms\_tactical) | ../modules/terraform-aws-optus-networks-vpc | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_iam_instance_profile.bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_security_group.vpc_endpoint](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.vpc_endpoint_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_vpc_endpoint.gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_region.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END_TF_DOCS -->
