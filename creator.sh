#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
B="\e[34m"
C="\e[36m"
M="\e[35m"
N="\e[0m"


HOSTED_ZONE="Z0738852208EFDOYXFTUB"
ZONE_NAME="opsora.space"
AMI_ID="ami-0220d79f3f480ecf5"
SG_ID="sg-0d34a14d6eba15d9d"

services=( "mongodb" "catalogue" "frontend" "redis" "user" "cart" "mysql" "shipping" "rabbitmq" "payment" "dispatch" )

for name in "${services[@]}"
do
  EXISTING_ID=$(
    aws ec2 describe-instances \
    --filters \
    "Name=tag:Name,Values=$name" \
    "Name=instance-state-name,Values=running,pending" \
    --query 'Reservations[*].Instances[*].InstanceId' \
    --output text
    )

  if [ -n "$EXISTING_ID" ];then
      echo -e " $G ${name} instance already exist. $Y Hence, skippping instance creation..$N"
  else
       echo -e " $R ${name} instance is not there. $G Hence, creating the instance... "
    if [ "$name" == "mongodb" ] || [ "$name" == "mysql" ] || [ "$name" == "shipping" ]; then
     INSTANCE_ID=$(
    aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type t3.medium \
    --security-group-ids "$SG_ID" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$name}]" \
    --query 'Instances[0].InstanceId' \
    --output text
     )
    elif [ "$name" == "catalogue" ] || [ "$name" == "frontend" ] || [ "$name" == "redis" ] || [ "$name" == "user" ] || [ "$name" == "cart" ] || [ "$name" == "rabbitmq" ] || [ "$name" == "payment" ] || [ "$name" == "dispatch" ] ; then
    INSTANCE_ID=$(
    aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type t3.micro \
    --security-group-ids "$SG_ID" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$name}]" \
    --query 'Instances[0].InstanceId' \
    --output text
    )
    fi

    echo -e "$G ${name} instance created successfully. Instance ID: $C $INSTANCE_ID $N"


    fi

    if [ "$name" == "frontend" ]; then
    IP=$(
   aws ec2 describe-instances \
        --filters Name=instance-id,Values="$INSTANCE_ID" \
        --query 'Reservations[*].Instances[*].PublicIpAddress' \
        --output text
    )
    RECORD_NAME="${ZONE_NAME}"

    else
    IP=$(
        aws ec2 describe-instances \
        --filters Name=instance-id,Values="$INSTANCE_ID" \
        --query 'Reservations[*].Instances[*].PrivateIpAddress' \
        --output text
        )
    RECORD_NAME="${name}.${ZONE_NAME}"
    fi
    
    echo -e " IP Address of the instance ${name} is : ${IP} "

    aws route53 change-resource-record-sets --hosted-zone-id "$HOSTED_ZONE" --change-batch '
    {
  "Comment": "Updating A record",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "'"$RECORD_NAME"'",
        "Type": "A",
        "TTL": 1,
        "ResourceRecords": [
          {
            "Value": "'$IP'"
          }
        ]
      }
    }
  ]
}

'
 echo "DNS record updated: ${RECORD_NAME} → ${IP}"
 echo -e "$M ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$N"



done