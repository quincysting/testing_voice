#!/bin/bash
# cleanup.sh
export AWS_PROFILE="Optus"
CLUSTER_NAME="mozart-tactical-cluster"

echo "Listing services in cluster: $CLUSTER_NAME"

# Get service names using AWS CLI query (no jq required)
mapfile -t SERVICE_NAMES < <(aws ecs list-services --cluster $CLUSTER_NAME --query 'serviceArns[*]' --output text | xargs -n1 | sed 's|.*/||')

if [ ${#SERVICE_NAMES[@]} -eq 0 ]; then
    echo "No services found in cluster"
    exit 0
fi

echo "Found ${#SERVICE_NAMES[@]} services: ${SERVICE_NAMES[*]}"

# 2. Stop all services
echo ""
echo "Stopping all services..."
for service in "${SERVICE_NAMES[@]}"; do
    echo "  Stopping service: $service"
    aws ecs update-service --cluster $CLUSTER_NAME --service $service --desired-count 0 > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "Successfully stopped"
    else
        echo "Failed to stop"
    fi
done

# 3. Wait for services to drain
echo ""
echo "Waiting for services to drain..."
sleep 60

# 4. Delete all services
echo ""
echo "Deleting all services..."
for service in "${SERVICE_NAMES[@]}"; do
    echo "  Deleting service: $service"
    aws ecs delete-service --cluster $CLUSTER_NAME --service $service --force > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "Successfully deleted"
    else
        echo "Failed to delete"
    fi
done

echo "Cleanup complete - processed ${#SERVICE_NAMES[@]} services"
