#!/bin/bash

# Script to create AWS SSM Parameters from .env.ssm file
# Usage: ./create-ssm-parameters.sh [env_file] [region] [aws_profile] [ssm_prefix]
# Example: ./create-ssm-parameters.sh .env.ssm ap-southeast-2 Optus /mozart-tactical-lab

set -e

ENV_FILE=${1:-.env.ssm}
REGION=${2:-ap-southeast-2}
AWS_PROFILE=${3:-Optus}
SSM_PREFIX=${4:-/mozart-tactical-lab}

# Set AWS profile if provided
if [ -n "$AWS_PROFILE" ]; then
    export AWS_PROFILE="$AWS_PROFILE"
    echo "Using AWS profile: $AWS_PROFILE"
fi

# Check if env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: Environment file '$ENV_FILE' not found!"
    echo "Usage: $0 [env_file] [region] [aws_profile] [ssm_prefix]"
    echo "Example: $0 .env.ssm ap-southeast-2 Optus /mozart-tactical-lab"
    echo ""
    echo "Please copy .env.ssm.example to .env.ssm and fill in your values:"
    echo "cp .env.ssm.example .env.ssm"
    exit 1
fi

echo "Creating SSM parameters from $ENV_FILE in region: $REGION"
echo "AWS Profile: $AWS_PROFILE"
echo "SSM prefix: $SSM_PREFIX"
echo ""

# Function to create an SSM parameter
create_ssm_parameter() {
    local param_name=$1
    local description=$2
    local param_value=$3
    local param_type=${4:-String}
    
    echo "Creating SSM parameter: $param_name"
    
    # Check if parameter already exists
    if aws ssm get-parameter --name "$param_name" --region "$REGION" >/dev/null 2>&1; then
        echo "  Parameter already exists, updating..."
        aws ssm put-parameter \
            --name "$param_name" \
            --description "$description" \
            --value "$param_value" \
            --type "$param_type" \
            --overwrite \
            --region "$REGION" \
            --tags Key=Environment,Value=lab Key=Application,Value=mozart Key=Module,Value=shared \
            >/dev/null
    else
        echo "  Creating new parameter..."
        aws ssm put-parameter \
            --name "$param_name" \
            --description "$description" \
            --value "$param_value" \
            --type "$param_type" \
            --region "$REGION" \
            --tags Key=Environment,Value=lab Key=Application,Value=mozart Key=Module,Value=shared \
            >/dev/null
    fi
    
    echo "  Parameter created/updated successfully"
}

# Function to read value from .env file
get_env_value() {
    local key=$1
    local value=$(grep "^${key}=" "$ENV_FILE" | cut -d'=' -f2- | sed 's/^"//;s/"$//')
    echo "$value"
}

# Check if required environment variables exist for SSM parameters
REQUIRED_SSM_VARS=(
    "AWS_REGION"
    "APNS_ENVIRONMENT"
    "SMS_PROVIDER"
    "EMAIL_PROVIDER"
    "AWS_S3_BUCKET_NAME"
    "TWILIO_ACCOUNT_SID"
    "SMS_FROM_NUMBER"
    "AWS_FROM_EMAIL"
    "SMPP_SYSTEM_ID"
    "RUN_REAL_SMS_TESTS"
    "SMPP_SERVER_HOST"
    "SMPP_SOURCE_ADDRESS"
    "TEST_SMS_RECIPIENT"
    "SMSGLOBAL_USERNAME"
)

MISSING_SSM_VARS=()

for var in "${REQUIRED_SSM_VARS[@]}"; do
    value=$(get_env_value "$var")
    if [ -z "$value" ]; then
        MISSING_SSM_VARS+=("$var")
    fi
done

if [ ${#MISSING_SSM_VARS[@]} -gt 0 ]; then
    echo "Warning: Missing SSM parameter variables in $ENV_FILE:"
    printf '  %s\n' "${MISSING_SSM_VARS[@]}"
    echo ""
    echo "These parameters will be skipped. Add them to your .env.ssm file if needed:"
    for var in "${MISSING_SSM_VARS[@]}"; do
        echo "$var=your_value_here"
    done
    echo ""
fi

# Create all SSM parameters
echo "=== Creating SSM Parameters ==="

# AWS Region
if AWS_REGION=$(get_env_value "AWS_REGION") && [ -n "$AWS_REGION" ]; then
    create_ssm_parameter \
        "$SSM_PREFIX/AWS_REGION" \
        "AWS Region for Mozart Lab" \
        "$AWS_REGION"
fi

# APNS Environment
if APNS_ENVIRONMENT=$(get_env_value "APNS_ENVIRONMENT") && [ -n "$APNS_ENVIRONMENT" ]; then
    create_ssm_parameter \
        "$SSM_PREFIX/APNS_ENVIRONMENT" \
        "Apple Push Notification Service Environment" \
        "$APNS_ENVIRONMENT"
fi

# SMS Provider
if SMS_PROVIDER=$(get_env_value "SMS_PROVIDER") && [ -n "$SMS_PROVIDER" ]; then
    create_ssm_parameter \
        "$SSM_PREFIX/SMS_PROVIDER" \
        "SMS service provider" \
        "$SMS_PROVIDER"
fi

# Email Provider
if EMAIL_PROVIDER=$(get_env_value "EMAIL_PROVIDER") && [ -n "$EMAIL_PROVIDER" ]; then
    create_ssm_parameter \
        "$SSM_PREFIX/EMAIL_PROVIDER" \
        "Email service provider" \
        "$EMAIL_PROVIDER"
fi

# AWS S3 Bucket Name
if AWS_S3_BUCKET_NAME=$(get_env_value "AWS_S3_BUCKET_NAME") && [ -n "$AWS_S3_BUCKET_NAME" ]; then
    create_ssm_parameter \
        "$SSM_PREFIX/AWS_S3_BUCKET_NAME" \
        "AWS S3 bucket name for artifacts" \
        "$AWS_S3_BUCKET_NAME"
fi

# Twilio Account SID
if TWILIO_ACCOUNT_SID=$(get_env_value "TWILIO_ACCOUNT_SID") && [ -n "$TWILIO_ACCOUNT_SID" ]; then
    create_ssm_parameter \
        "$SSM_PREFIX/TWILIO_ACCOUNT_SID" \
        "Twilio Account SID" \
        "$TWILIO_ACCOUNT_SID"
fi

# SMS From Number
if SMS_FROM_NUMBER=$(get_env_value "SMS_FROM_NUMBER") && [ -n "$SMS_FROM_NUMBER" ]; then
    create_ssm_parameter \
        "$SSM_PREFIX/SMS_FROM_NUMBER" \
        "SMS sender phone number" \
        "$SMS_FROM_NUMBER"
fi

# AWS From Email
if AWS_FROM_EMAIL=$(get_env_value "AWS_FROM_EMAIL") && [ -n "$AWS_FROM_EMAIL" ]; then
    create_ssm_parameter \
        "$SSM_PREFIX/AWS_FROM_EMAIL" \
        "AWS SES sender email address" \
        "$AWS_FROM_EMAIL"
fi

# SMPP System ID
if SMPP_SYSTEM_ID=$(get_env_value "SMPP_SYSTEM_ID") && [ -n "$SMPP_SYSTEM_ID" ]; then
    create_ssm_parameter \
        "$SSM_PREFIX/SMPP_SYSTEM_ID" \
        "SMPP System ID for SMS Global" \
        "$SMPP_SYSTEM_ID"
fi

# Run Real SMS Tests
if RUN_REAL_SMS_TESTS=$(get_env_value "RUN_REAL_SMS_TESTS") && [ -n "$RUN_REAL_SMS_TESTS" ]; then
    create_ssm_parameter \
        "$SSM_PREFIX/RUN_REAL_SMS_TESTS" \
        "Enable real SMS tests" \
        "$RUN_REAL_SMS_TESTS"
fi

# SMPP Server Host
if SMPP_SERVER_HOST=$(get_env_value "SMPP_SERVER_HOST") && [ -n "$SMPP_SERVER_HOST" ]; then
    create_ssm_parameter \
        "$SSM_PREFIX/SMPP_SERVER_HOST" \
        "SMPP server hostname" \
        "$SMPP_SERVER_HOST"
fi

# SMPP Source Address
if SMPP_SOURCE_ADDRESS=$(get_env_value "SMPP_SOURCE_ADDRESS") && [ -n "$SMPP_SOURCE_ADDRESS" ]; then
    create_ssm_parameter \
        "$SSM_PREFIX/SMPP_SOURCE_ADDRESS" \
        "SMPP source address/phone number" \
        "$SMPP_SOURCE_ADDRESS"
fi

# Test SMS Recipient
if TEST_SMS_RECIPIENT=$(get_env_value "TEST_SMS_RECIPIENT") && [ -n "$TEST_SMS_RECIPIENT" ]; then
    create_ssm_parameter \
        "$SSM_PREFIX/TEST_SMS_RECIPIENT" \
        "Test SMS recipient phone number" \
        "$TEST_SMS_RECIPIENT"
fi

# SMS Global Username
if SMSGLOBAL_USERNAME=$(get_env_value "SMSGLOBAL_USERNAME") && [ -n "$SMSGLOBAL_USERNAME" ]; then
    create_ssm_parameter \
        "$SSM_PREFIX/SMSGLOBAL_USERNAME" \
        "SMS Global username" \
        "$SMSGLOBAL_USERNAME"
fi

echo ""
echo "=== SSM Parameter Creation Complete ==="
echo ""
echo "All SSM parameters have been created/updated successfully!"
echo ""
echo "You can verify the parameters using:"
echo "aws ssm get-parameters-by-path --path $SSM_PREFIX --region $REGION"
echo ""
echo "To see parameter details:"
echo "aws ssm describe-parameters --region $REGION --filters Key=Name,Values=$SSM_PREFIX"
