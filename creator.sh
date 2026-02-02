#!/bin/bash

HOSTED_ZONE="Z0738852208EFDOYXFTUB"
ZONE_NAME="opsora.space"
AMI_ID="ami-0220d79f3f480ecf5"
SG_ID="sg-0d34a14d6eba15d9d"

services=( "mongodb" "catalogue" "frontend" "redis" "user" "cart" "mysql" "shipping" "rabbitmq" "payment" "dispatch" )

for name in "${services[@]}"
do
  EXISTING_ID=$(
    aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=$name" \
    "Name=instance-state-name,Values=running,pending" \
    --query 'Reservations[*].Instances[*].InstanceId' \
    --output text)

  if [ -n "$EXISTING_ID" ];then
      echo " ${name} instance already exist. Hence, skippping instance creation.."
  else
       echo " ${name} instance is not there. Hence, creating the instance... "
    if [ $name == "mongodb" ] || [ $name == "mysql" ] || [ $name == "shipping" ]; then
     INSTANCE_ID=$(
    aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type t3.medium \
    --security-group-ids $SG_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$name}]" \
    --query 'Instances[0].InstanceId' \
    --output text
     )
    elif [ $name == "catalogue" ] || [ $name == "frontend" ] || [ $name == "redis" ] || [ $name == "user" ] || [ $name == "cart" ] || [ $name == "rabbitmq" ] || [ $name == "payment" ] || [ $name == "dispatch" ] ; then
    INSTANCE_ID=$(
    aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type t3.micro \
    --security-group-ids $SG_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$name}]" \
    --query 'Instances[0].InstanceId' \
    --output text
    )
    fi

    echo -e " ${name} is succesfully created :) "
    fi

    if [ $name == "frontend" ]; then
    IP=$(
    aws ec2 describe-instances \
    --filters Name=tag:Name,Values=$name \
    --query 'Reservations[*].Instances[*].PublicIpAddress' 
    --output text)
    RECORD_NAME="$ZONE_NAME"
    else
    IP=$(
        aws ec2 describe-instances \
    --filters Name=tag:Name,Values=$name \
    --query 'Reservations[*].Instances[*].PrivateIpAddress' 
    --output text)
    RECORD_NAME="$name.$ZONE_NAME"
    fi
    echo -e " IP Address of the instance ${name} is : ${IP} "

    aws route53 change-resource-record-sets --hosted-zone-id ${ZONE_ID} --change-batch '
    {
  "Comment": "Updating A record",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "'$RECORD_NAME'",
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

echo "Instance ${name} is succesfully created. And IP Address ${IP} is assigned to it also ${RECORD_NAME} has been updated"
      

done