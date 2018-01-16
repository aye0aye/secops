#!/bin/bash -e
set -o pipefail

RES_AWS_CREDS=$1
OUT_AMI_SEC_APPRD=$2

# Now get AWS keys
AWS_ACCESS_KEY_ID=$(shipctl get_integration_resource_field $RES_AWS_CREDS ACCESSKEY)
AWS_SECRET_ACCESS_KEY=$(shipctl get_integration_resource_field $RES_AWS_CREDS SECRETKEY)

set_context(){
  echo "RES_AWS_CREDS=$RES_AWS_CREDS"
  echo "OUT_AMI_SEC_APPRD=$OUT_AMI_SEC_APPRD"

  echo "REGION=$REGION"
  echo "SOURCE_AMI=$BASE_ECS_AMI"
  echo "VPC_ID=$AMI_VPC_ID"
  echo "SUBNET_ID=$AMI_PUBLIC_SN_ID"
  echo "SECURITY_GROUP_ID=$AMI_PUBLIC_SG_ID"
  echo "AWS_ACCESS_KEY_ID=${#AWS_ACCESS_KEY_ID}" #print only length not value
  echo "AWS_SECRET_ACCESS_KEY=${#AWS_SECRET_ACCESS_KEY}" #print only length not value
}

build_ecs_ami() {
  echo "validating AMI template"
  echo "-----------------------------------"
  packer validate baseAMI.json
  echo "building AMI"
  echo "-----------------------------------"

  packer build \
    -var aws_access_key=$AWS_ACCESS_KEY_ID \
    -var aws_secret_key=$AWS_SECRET_ACCESS_KEY \
    -var REGION=$REGION \
    -var VPC_ID=$AMI_VPC_ID \
    -var SUBNET_ID=$AMI_PUBLIC_SN_ID \
    -var SECURITY_GROUP_ID=$AMI_PUBLIC_SG_ID \
    -var SOURCE_AMI=$BASE_ECS_AMI \
    baseAMI.json

    AMI_ID=$(shipctl get_json_value manifest.json builds[0].artifact_id | cut -d':' -f 2)

    # create version for ami param
    shipctl post_resource_state $JOB_NAME versionName $AMI_ID
    shipctl post_resource_state_multi $OUT_AMI_SEC_APPRD \
      "versionName=$AMI_ID \
      AMI_ID=$AMI_ID"
}

main() {
  eval `ssh-agent -s`
  which ssh-agent

  set_context
  build_ecs_ami
}

main
