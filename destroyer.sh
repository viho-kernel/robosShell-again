#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
C="\e[36m"
M="\e[35m"
N="\e[0m"

HOSTED_ZONE="Z0738852208EFDOYXFTUB"
ZONE_NAME="opsora.space"

services=("mongodb" "catalogue" "frontend" "redis" "user" "cart" "mysql" "shipping" "rabbitmq" "payment" "dispatch")

for name in "${services[@]}"; do
  INSTANCE_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=$name" "Name=instance-state-name,Values=running,pending,stopped" \
    --query 'Reservations[*].Instances[*].InstanceId' \
    --output text)

  if [ -n "$INSTANCE_ID" ]; then
    echo -e "$R Terminating $name instance (ID: $C$INSTANCE_ID$N)..."
    aws ec2 terminate-instances --instance-ids "$INSTANCE_ID"

    # Get IP before DNS deletion
    if [ "$name" == "frontend" ]; then
      IP=$(aws ec2 describe-instances \
        --instance-ids "$INSTANCE_ID" \
        --query 'Reservations[*].Instances[*].PublicIpAddress' \
        --output text)
      RECORD_NAME="${ZONE_NAME}"
    else
      IP=$(aws ec2 describe-instances \
        --instance-ids "$INSTANCE_ID" \
        --query 'Reservations[*].Instances[*].PrivateIpAddress' \
        --output text)
      RECORD_NAME="${name}.${ZONE_NAME}"
    fi

    if [ -n "$IP" ]; then
      aws route53 change-resource-record-sets --hosted-zone-id "$HOSTED_ZONE" --change-batch "{
        \"Comment\": \"Deleting A record\",
        \"Changes\": [
          {
            \"Action\": \"DELETE\",
            \"ResourceRecordSet\": {
              \"Name\": \"$RECORD_NAME\",
              \"Type\": \"A\",
              \"TTL\": 1,
              \"ResourceRecords\": [
                { \"Value\": \"$IP\" }
              ]
            }
          }
        ]
      }"
      echo -e "$G DNS record deleted: $C$RECORD_NAME --> $IP$N"
    else
      echo -e "$Y No IP found for $name, skipping DNS deletion.$N"
    fi
  else
    echo -e "$Y No instance found for $name, skipping...$N"
  fi

  echo -e "$M ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$N"
done

echo -e "$R All instance are terminated. DNS cleaned.$N"
