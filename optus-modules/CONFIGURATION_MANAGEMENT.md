# Configuration Management Architecture

This document provides a comprehensive overview of the modern SSM Parameter Store and AWS Secrets Manager approach implemented for the Mozart Lab infrastructure.

## Overview

The Mozart Lab infrastructure has been modernized to use a centralized, external configuration management approach that separates concerns between infrastructure and configuration, following security best practices and improving maintainability.

## Architecture Components

### 1. External Configuration Scripts (`optus-scripts/`)

Configuration is managed externally through dedicated shell scripts that create AWS resources before infrastructure deployment.

#### SSM Parameters Script
- **File**: `create-ssm-parameters.sh`
- **Purpose**: Creates non-sensitive configuration parameters
- **Input**: `.env.ssm` file
- **Scope**: Application settings, service endpoints, feature flags

#### Secrets Manager Script  
- **File**: `create-secrets-from-env.sh`
- **Purpose**: Creates sensitive credentials and API keys
- **Input**: `.env.secrets` file
- **Scope**: Passwords, tokens, private keys, certificates

### 2. Centralized Configuration (`shared-config.tf`)

All parameter and secret definitions are centralized in a single configuration file that:
- Defines standard parameter names with configurable prefixes
- Maps logical names to AWS resource names
- Provides data sources for infrastructure consumption
- Handles dynamic connection string construction

### 3. Module Integration (`main.tf`)

Application modules automatically receive configuration through:
- SSM parameters as environment variables
- Secrets Manager secrets as container secrets
- Dynamic connection strings as environment variables

## Configuration Categories

### Non-Sensitive Parameters (SSM Parameter Store)

**AWS Configuration:**
- `AWS_REGION` - AWS region for services
- `AWS_S3_BUCKET_NAME` - S3 bucket for artifacts
- `AWS_FROM_EMAIL` - SES sender email address

**Service Configuration:**
- `APNS_ENVIRONMENT` - Apple Push Notification environment (sandbox/production)
- `SMS_PROVIDER` - SMS service provider (twilio/smsglobal)
- `EMAIL_PROVIDER` - Email service provider (aws/sendgrid)
- `REDIS_MAX_CONNECTION` - Maximum Redis connections

**Communication Settings:**
- `TWILIO_ACCOUNT_SID` - Twilio account identifier (non-sensitive)
- `SMS_FROM_NUMBER` - SMS sender phone number
- `SMPP_SYSTEM_ID` - SMPP system identifier
- `SMPP_SERVER_HOST` - SMPP server hostname
- `SMPP_SOURCE_ADDRESS` - SMPP source phone number
- `SMSGLOBAL_USERNAME` - SMS Global username

**Testing Configuration:**
- `RUN_REAL_SMS_TESTS` - Enable/disable real SMS testing
- `TEST_SMS_RECIPIENT` - Test SMS recipient phone number

### Sensitive Secrets (AWS Secrets Manager)

**API Keys and Tokens:**
- `JWT_SECRET` - JWT signing secret
- `TWILIO_AUTH_TOKEN` - Twilio authentication token
- `SMPP_PASSWORD` - SMPP authentication password
- `SMSGLOBAL_PASSWORD` - SMS Global password

**Authentication Credentials:**
- `AUTH_PASSWORD` - Application authentication password

**External Service Credentials:**
- `AAI_API_KEY` - AssemblyAI API key (optional)
- `AAI_HOSTNAME` - AssemblyAI service endpoint (optional)
- `AAI_WEBHOOK_URL` - AssemblyAI webhook URL (optional)

**Private Keys:**
- `APNS_KEY` - Apple Push Notification private key (optional)

**Database Passwords:**
- `SUBSCRIBER_DB_PASSWORD` - Aurora RDS password (from database modules)
- `KAM_DB_PASSWORD` - Kamailio RDS password (from database modules)

### Dynamic Configuration (Infrastructure-Derived)

**Connection Strings:**
- `DB_CONNECTION` - Dynamically constructed PostgreSQL connection string
- `REDIS_CONNECTION` - Dynamically constructed Redis connection string

## Configuration Prefix System

All parameters and secrets use a configurable prefix system:

**Default Prefix:** `/mozart-tactical-lab`

**Configurable Through:**
- `config_prefix` variable in `shared-config.tf`
- `SECRETS_PREFIX` in `create-secrets-from-env.sh`  
- `SSM_PREFIX` in `create-ssm-parameters.sh`

**Benefits:**
- Environment separation (dev/staging/prod)
- Multi-tenant support
- Namespace isolation

## Security Best Practices

### 1. Separation of Sensitive Data
- **Non-sensitive**: SSM Parameter Store (cheaper, simpler)
- **Sensitive**: Secrets Manager (encrypted, auditable, rotatable)

### 2. Dynamic Connection Construction
- Connection strings built from live infrastructure endpoints
- Database passwords referenced from separate secret store
- No hardcoded connection details in configuration

### 3. External Secret Management
- Secrets created outside of Terraform
- No sensitive data in Terraform state files
- Scripts validate required secrets exist before deployment

### 4. Infrastructure Integration
- Applications receive only ARNs, not actual secret values
- AWS handles secret retrieval and injection
- Proper IAM permissions required for secret access

## Deployment Workflow

### 1. Prepare Configuration Files
```bash
# Copy templates
cp .env.ssm.example .env.ssm
cp .env.secrets.example .env.secrets

# Fill in actual values (never commit these files!)
vim .env.ssm
vim .env.secrets
```

### 2. Create External Configuration
```bash
# Create SSM parameters (using Optus AWS profile)
./create-ssm-parameters.sh .env.ssm ap-southeast-2 Optus

# Create secrets (using Optus AWS profile)
./create-secrets-from-env.sh .env.secrets ap-southeast-2 Optus
```

### 3. Deploy Infrastructure
```bash
# Deploy database infrastructure first
cd optus-db-lab/terraform
terraform apply

# Deploy application infrastructure
cd ../../optus-modules
terraform apply
```

## Migration from Legacy Approach

### Before (Legacy)
- Hardcoded values in Terraform files
- Mixed sensitive/non-sensitive data
- Terraform-managed secrets
- Manual parameter creation
- Environment-specific hardcoding

### After (Modern)
- External configuration management
- Clear sensitive/non-sensitive separation
- Script-managed secrets
- Automated parameter creation
- Configurable prefixes and environments

## File Structure

```
optus-scripts/
├── create-ssm-parameters.sh      # SSM parameter creation
├── create-secrets-from-env.sh    # Secrets Manager creation
├── .env.ssm.example             # SSM parameter template
├── .env.secrets.example         # Secrets template
├── .env.ssm                     # Actual SSM values (gitignored)
└── .env.secrets                 # Actual secrets (gitignored)

optus-modules/
├── shared-config.tf             # Centralized configuration
├── main.tf                      # Module integration
├── data.tf                      # Data sources
└── CONFIGURATION_MANAGEMENT.md  # This document

optus-db-lab/
└── terraform/
    ├── modules/                 # Database modules
    └── outputs.tf              # Database secret ARNs
```

## Troubleshooting

### Verify Parameters Exist
```bash
# List SSM parameters (using Optus profile)
aws ssm get-parameters-by-path --path /mozart-tactical-lab --region ap-southeast-2 --profile Optus

# List secrets (using Optus profile)
aws secretsmanager list-secrets --filters Key=name,Values=/mozart-tactical-lab --region ap-southeast-2 --profile Optus
```

### Check Configuration Access
```bash
# Test SSM parameter access (using Optus profile)
aws ssm get-parameter --name /mozart-tactical-lab/AWS_REGION --region ap-southeast-2 --profile Optus

# Test secret access (using Optus profile)
aws secretsmanager get-secret-value --secret-id /mozart-tactical-lab/JWT_SECRET --region ap-southeast-2 --profile Optus
```

### Validate Terraform Configuration
```bash
terraform validate
terraform plan
```

## Benefits of New Approach

### Security
- Sensitive data never in Terraform state
- Proper encryption for secrets
- Audit trails for secret access
- Rotation capability for secrets

### Maintainability  
- Centralized configuration management
- Clear separation of concerns
- Environment-agnostic infrastructure code
- Automated parameter/secret creation

### Flexibility
- Configurable prefixes for multi-environment
- Easy to add new parameters/secrets
- Dynamic connection string construction
- Infrastructure-derived configuration

### Developer Experience
- Clear documentation and examples
- Validation of required configuration
- Automated distribution to applications
- Consistent naming conventions

## Future Enhancements

- Integration with AWS Parameter Store hierarchies
- Automatic secret rotation policies
- Configuration drift detection
- Multi-region parameter replication
- GitOps integration for configuration changes