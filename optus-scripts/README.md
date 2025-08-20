# Modern Secret Management

This module follows modern Terraform best practices by referencing existing AWS Secrets Manager secrets rather than creating them in Terraform state.

## Prerequisites

Before deploying this module, you must create the required secrets in AWS Secrets Manager using the provided script in the `optus-scripts` directory.

## Setup Instructions

### 1. Create Environment Files

Copy the example environment files and fill in your actual values:

```bash
cd optus-scripts

# Copy SSM parameters template
cp .env.ssm.example .env.ssm

# Copy secrets template  
cp .env.secrets.example .env.secrets
```

Edit the `.env.ssm` file with your non-sensitive configuration:

```bash
# AWS Configuration
AWS_REGION=ap-southeast-2
APNS_ENVIRONMENT=sandbox
REDIS_MAX_CONNECTION=50
SMS_PROVIDER=twilio
EMAIL_PROVIDER=aws
AWS_S3_BUCKET_NAME=lab-mozart-assets-bucket
TWILIO_ACCOUNT_SID=AC91dd724da37a87d80a309b761d0128ad
SMS_FROM_NUMBER=+16088892652
AWS_FROM_EMAIL=xiaoyi.lu@norwoodsystems.com
DB_CONNECTION=postgres://mozart_user:${DB_PASSWORD}@your-db-endpoint:5432/mozartlab?sslmode=require
REDIS_CONNECTION=redis://your-redis-endpoint:6379
```

Edit the `.env.secrets` file with your sensitive data:

```bash
# Sensitive secrets
AAI_API_KEY=your_actual_assemblyai_api_key
AAI_HOSTNAME=https://api.assemblyai.com/v2/transcript
AAI_WEBHOOK_URL=your_actual_webhook_url
APNS_KEY=-----BEGIN PRIVATE KEY-----\nYOUR_ACTUAL_APNS_KEY\n-----END PRIVATE KEY-----
JWT_SECRET=your_actual_jwt_secret
AUTH_PASSWORD=your_actual_password
TWILIO_AUTH_TOKEN=your_actual_twilio_token
```

### 2. Create SSM Parameters and Secrets

Run both scripts to create the required configuration and secrets:

```bash
# Make sure you have AWS CLI configured with appropriate permissions
cd optus-scripts

# Create SSM parameters for non-sensitive configuration
./create-ssm-parameters.sh .env.ssm ap-southeast-2

# Create Secrets Manager secrets for sensitive data
./create-secrets-from-env.sh .env.secrets ap-southeast-2
```

Or use the default files (the scripts will automatically use .env.ssm and .env.secrets):

```bash
# Using default files
./create-ssm-parameters.sh
./create-secrets-from-env.sh
```

These scripts will:

**SSM Parameters Script:**
- Read configuration values from your `.env.ssm` file
- Create AWS SSM parameters with the prefix `/mozart-lab/`
- Skip creation if parameters already exist
- Use String type for non-sensitive configuration

**Secrets Manager Script:**
- Read sensitive values from your `.env.secrets` file  
- Create AWS Secrets Manager secrets with the prefix `/mozart-lab/`
- Skip creation if secrets already exist
- Add appropriate tags for organization

### 3. Deploy with Terraform

Once the secrets are created, you can deploy the module:

```bash
terraform apply
```

## Secret Management Best Practices

### ✅ What This Approach Provides

- **Security**: No secrets stored in Terraform state files
- **Compliance**: Meets security compliance requirements
- **Separation of Concerns**: Secret management is handled externally
- **Audit Trail**: Better tracking of secret access and changes
- **Rotation**: Secrets can be rotated without Terraform changes
- **Portability**: Works across different AWS accounts and regions

### 🔄 Secret Rotation

To rotate secrets:

1. Update the secret value in AWS Secrets Manager:

```bash
aws secretsmanager update-secret \
  --secret-id "/mozart-lab/AAI_API_KEY" \
  --secret-string '{"key": "new_api_key"}' \
  --region ap-southeast-2
```

2. No Terraform changes required - the application will automatically use the new secret value.

### 🔍 Verifying Configuration

Check that all SSM parameters exist:

```bash
aws ssm get-parameters-by-path \
  --path "/mozart-lab" \
  --region ap-southeast-2
```

Check that all secrets exist:

```bash
aws secretsmanager list-secrets \
  --region ap-southeast-2 \
  --filters Key=name,Values=/mozart-lab/
```

## Required Configuration

### SSM Parameters (Non-Sensitive)

The following parameters must exist in AWS Systems Manager Parameter Store:

- `/mozart-lab/AWS_REGION` - AWS Region
- `/mozart-lab/APNS_ENVIRONMENT` - Apple Push Notification Service Environment
- `/mozart-lab/REDIS_MAX_CONNECTION` - Maximum Redis connections
- `/mozart-lab/SMS_PROVIDER` - SMS service provider
- `/mozart-lab/EMAIL_PROVIDER` - Email service provider
- `/mozart-lab/AWS_S3_BUCKET_NAME` - AWS S3 bucket name
- `/mozart-lab/TWILIO_ACCOUNT_SID` - Twilio Account SID
- `/mozart-lab/SMS_FROM_NUMBER` - SMS sender phone number
- `/mozart-lab/AWS_FROM_EMAIL` - AWS SES sender email
- `/mozart-lab/DB_CONNECTION` - Database connection string
- `/mozart-lab/REDIS_CONNECTION` - Redis connection string

### Secrets Manager (Sensitive)

The following secrets must exist in AWS Secrets Manager:

- `/mozart-lab/AAI_API_KEY` - AssemblyAI API Key
- `/mozart-lab/AAI_HOSTNAME` - AssemblyAI Hostname
- `/mozart-lab/AAI_WEBHOOK_URL` - AssemblyAI Webhook URL
- `/mozart-lab/APNS_KEY` - Apple Push Notification Service Private Key
- `/mozart-lab/JWT_SECRET` - JWT Secret for authentication
- `/mozart-lab/AUTH_PASSWORD` - Authentication password
- `/mozart-lab/TWILIO_AUTH_TOKEN` - Twilio Auth Token

## Troubleshooting

### Error: Parameter/Secret not found

If you get an error about a parameter or secret not existing:

1. Check that the SSM parameter was created:

```bash
aws ssm get-parameter --name "/mozart-lab/PARAMETER_NAME" --region ap-southeast-2
```

2. Check that the secret was created:

```bash
aws secretsmanager describe-secret --secret-id "/mozart-lab/SECRET_NAME" --region ap-southeast-2
```

3. Re-run the creation scripts:

```bash
cd optus-scripts
./create-ssm-parameters.sh .env.ssm ap-southeast-2
./create-secrets-from-env.sh .env.secrets ap-southeast-2
```

### Error: Permission denied

Ensure your AWS credentials have the necessary permissions:

**For SSM Parameters:**
- `ssm:PutParameter`
- `ssm:GetParameter`
- `ssm:DescribeParameters`

**For Secrets Manager:**
- `secretsmanager:CreateSecret`
- `secretsmanager:DescribeSecret`
- `secretsmanager:GetSecretValue`

## Security Considerations

- **Never commit `.env.secrets` or `.env.ssm` files to git**
- Add both files to your `.gitignore`:
  ```
  .env.secrets
  .env.ssm
  ```
- Use IAM roles and policies to control access to secrets and parameters
- Enable encryption at rest for all secrets
- Implement secret rotation policies
- Monitor secret access through CloudTrail
- Use least privilege principle for secret access
- Store `.env.secrets` file securely and restrict access
- Consider using separate files for different environments (dev, staging, prod)
