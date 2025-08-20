# Database Password Integration Guide

This document explains how database passwords from the optus-db-lab infrastructure are exposed and made available to applications via shared-config.tf.

## Overview

The optus-db-lab terraform modules create RDS instances with automatically generated passwords stored in AWS Secrets Manager. These passwords are now exposed through the shared configuration system for use by applications.

## Database Modules

### Aurora RDS (Subscriber Database)
- **Module**: `optus-db-lab/terraform/modules/aurora_rds`
- **App Name**: `mozart-db-lab`
- **Secret Name**: `mozart-db-lab-db-password-lab`
- **Exposed As**: `SUBSCRIBER_DB_PASSWORD`

### Kamailio RDS
- **Module**: `optus-db-lab/terraform/modules/kamailio_rds`
- **App Name**: `kamailio-db-lab`
- **Secret Name**: `kamailio-db-lab-db-password-lab`
- **Exposed As**: `KAM_DB_PASSWORD`

## Integration Architecture

### 1. Database Modules Create Secrets
Each database module:
```hcl
resource "random_password" "db_password" {
  length  = 16
  special = false
}

resource "aws_secretsmanager_secret" "db_password" {
  name = "${var.app_name}-db-password-lab"
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db_password.result
}
```

### 2. Database Modules Output Secret ARNs
```hcl
output "password_secret_arn" {
  value = aws_secretsmanager_secret.db_password.arn
}
```

### 3. Shared Config References Database Secrets
In `shared-config.tf`:
```hcl
locals {
  database_secret_names = {
    "SUBSCRIBER_DB_PASSWORD" = "mozart-db-lab-db-password-lab"
    "KAM_DB_PASSWORD"        = "kamailio-db-lab-db-password-lab"
  }
}

data "aws_secretsmanager_secret" "database_secrets" {
  for_each = local.database_secret_names
  name     = each.value
}
```

### 4. Applications Receive Database Passwords
Applications (IMAP, admin-dashboard) automatically receive:
- `SUBSCRIBER_DB_PASSWORD` - Aurora RDS password for subscriber database
- `KAM_DB_PASSWORD` - Kamailio RDS password for SIP/telephony database

## Usage in Applications

Applications can access these passwords as environment variables:

```bash
# Aurora RDS (Subscriber Database)
echo $SUBSCRIBER_DB_PASSWORD

# Kamailio RDS 
echo $KAM_DB_PASSWORD
```

## Best Practices Implemented

1. **Separation of Concerns**: Database infrastructure is separate from application infrastructure
2. **Secret Management**: Passwords are generated and managed by database modules
3. **Reference by Name**: Applications reference secrets by logical names, not ARNs
4. **Automatic Distribution**: All applications automatically receive database passwords
5. **Security**: Passwords never appear in Terraform state or logs - only ARNs are passed

## Security Considerations

- Database passwords are randomly generated (16 characters, no special chars)
- Passwords are stored in AWS Secrets Manager with encryption at rest
- Only applications with proper IAM permissions can access the secrets
- Secret ARNs are passed to containers, not the actual passwords
- Passwords can be rotated through AWS Secrets Manager rotation

## Deployment Dependencies

1. Deploy `optus-db-lab` infrastructure first to create databases and secrets
2. Deploy `optus-modules` infrastructure second - it will reference the existing secrets
3. Applications will automatically receive database passwords via ECS task definitions

## Troubleshooting

### Check if secrets exist:
```bash
aws secretsmanager list-secrets --filters Key=name,Values=mozart-db-lab-db-password-lab
aws secretsmanager list-secrets --filters Key=name,Values=kamailio-db-lab-db-password-lab
```

### Verify secret access from application:
```bash
aws secretsmanager get-secret-value --secret-id mozart-db-lab-db-password-lab
aws secretsmanager get-secret-value --secret-id kamailio-db-lab-db-password-lab
```