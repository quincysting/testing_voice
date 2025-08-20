#!/bin/bash

# Script to create AWS Secrets Manager secrets from .env.secrets file
# Usage: ./create-secrets-from-env.sh [env_file] [region] [aws_profile] [secrets_prefix]
# Example: ./create-secrets-from-env.sh .env.secrets ap-southeast-2 Optus /mozart-tactical-lab

set -e

ENV_FILE=${1:-.env.secrets}
REGION=${2:-ap-southeast-2}
AWS_PROFILE=${3:-Optus}
SECRETS_PREFIX=${4:-/mozart-tactical-lab}

# Set AWS profile if provided
if [ -n "$AWS_PROFILE" ]; then
    export AWS_PROFILE="$AWS_PROFILE"
    echo "Using AWS profile: $AWS_PROFILE"
fi

# Check if secrets env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: Secrets file '$ENV_FILE' not found!"
    echo "Usage: $0 [env_file] [region] [aws_profile] [secrets_prefix]"
    echo "Example: $0 .env.secrets ap-southeast-2 Optus /mozart-tactical-lab"
    echo ""
    echo "Please copy .env.secrets.example to .env.secrets and fill in your values:"
    echo "cp .env.secrets.example .env.secrets"
    exit 1
fi

echo "Creating secrets from $ENV_FILE in region: $REGION"
echo "AWS Profile: $AWS_PROFILE"
echo "Secrets prefix: $SECRETS_PREFIX"
echo ""

# Function to create a secret
create_secret() {
    local secret_name=$1
    local description=$2
    local secret_value=$3
    
    echo "Creating secret: $secret_name"
    
    # Check if secret already exists
    if aws secretsmanager describe-secret --secret-id "$secret_name" --region "$REGION" >/dev/null 2>&1; then
        echo "  Secret already exists, skipping..."
        return 0
    fi
    
    # Create the secret
    aws secretsmanager create-secret \
        --name "$secret_name" \
        --description "$description" \
        --secret-string "$secret_value" \
        --region "$REGION" \
        --tags Key=Environment,Value=lab Key=Application,Value=mozart Key=Module,Value=imap
    
    echo "  Secret created successfully"
}

# Function to read value from .env file
get_env_value() {
    local key=$1
    local value=$(grep "^${key}=" "$ENV_FILE" | cut -d'=' -f2- | sed 's/^"//;s/"$//')
    echo "$value"
}

# Check if required environment variables exist
REQUIRED_VARS=(
    "JWT_SECRET"
    "AUTH_PASSWORD"
    "TWILIO_AUTH_TOKEN"
    "SMPP_PASSWORD"
    "SMSGLOBAL_PASSWORD"
)

MISSING_VARS=()

for var in "${REQUIRED_VARS[@]}"; do
    value=$(get_env_value "$var")
    if [ -z "$value" ]; then
        MISSING_VARS+=("$var")
    fi
done

if [ ${#MISSING_VARS[@]} -gt 0 ]; then
    echo "Error: Missing required environment variables in $ENV_FILE:"
    printf '  %s\n' "${MISSING_VARS[@]}"
    echo ""
    echo "Please add these variables to your .env.secrets file:"
    for var in "${MISSING_VARS[@]}"; do
        echo "$var=your_value_here"
    done
    exit 1
fi

# Create all required secrets
echo "=== Creating Application Secrets ==="

# JWT Secret
JWT_SECRET=$(get_env_value "JWT_SECRET")
create_secret \
    "$SECRETS_PREFIX/JWT_SECRET" \
    "JWT Secret for Mozart Lab" \
    "{\"secret\": \"$JWT_SECRET\"}"

# Auth Password
AUTH_PASSWORD=$(get_env_value "AUTH_PASSWORD")
create_secret \
    "$SECRETS_PREFIX/AUTH_PASSWORD" \
    "Authentication Password for Mozart Lab" \
    "$AUTH_PASSWORD"

# Twilio Auth Token
TWILIO_AUTH_TOKEN=$(get_env_value "TWILIO_AUTH_TOKEN")
create_secret \
    "$SECRETS_PREFIX/TWILIO_AUTH_TOKEN" \
    "Twilio Auth Token" \
    "$TWILIO_AUTH_TOKEN"

# SMPP Password
SMPP_PASSWORD=$(get_env_value "SMPP_PASSWORD")
create_secret \
    "$SECRETS_PREFIX/SMPP_PASSWORD" \
    "SMPP Password for SMS Global" \
    "$SMPP_PASSWORD"

# SMS Global Password
SMSGLOBAL_PASSWORD=$(get_env_value "SMSGLOBAL_PASSWORD")
create_secret \
    "$SECRETS_PREFIX/SMSGLOBAL_PASSWORD" \
    "SMS Global Password" \
    "$SMSGLOBAL_PASSWORD"

echo ""
echo "=== Secret Creation Complete ==="
echo ""
echo "All secrets have been created successfully!"
echo ""
echo "You can verify the secrets using:"
echo "aws secretsmanager list-secrets --region $REGION --filters Key=name,Values=$SECRETS_PREFIX" 
