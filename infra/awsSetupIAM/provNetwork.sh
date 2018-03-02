#!/bin/bash -e
set -o pipefail

ACTION=$1
STATE_RES=$2
RES_AWS_CREDS="demo_aws_cli"
OUT_AMI_VPC="ami_vpc_info"
OUT_TEST_VPC="test_vpc_info"
OUT_PROD_VPC="prod_vpc_info"
TF_STATEFILE="terraform.tfstate"

AWS_ACCESS_KEY_ID=$(shipctl get_integration_resource_field $RES_AWS_CREDS ACCESSKEY)
AWS_SECRET_ACCESS_KEY=$(shipctl get_integration_resource_field $RES_AWS_CREDS SECRETKEY)

set_context(){
  echo "RES_AWS_CREDS=$RES_AWS_CREDS"

  echo "AWS_ACCESS_KEY_ID=${#AWS_ACCESS_KEY_ID}" #print only length not value
  echo "AWS_SECRET_ACCESS_KEY=${#AWS_SECRET_ACCESS_KEY}" #print only length not value

  echo "region=$REGION"

  # This restores the terraform state file
  shipctl copy_file_from_resource_state $STATE_RES $TF_STATEFILE .

  # now setup the variables based on context
  # naming the file terraform.tfvars makes terraform automatically load it
  echo "aws_access_key_id = \"$AWS_ACCESS_KEY_ID\"" > terraform.tfvars
  echo "aws_secret_access_key = \"$AWS_SECRET_ACCESS_KEY\"" >> terraform.tfvars
  echo "region = \"$REGION\"" >> terraform.tfvars
  echo "ami_vpc = \"$AMI_VPC\"" >> terraform.tfvars
  echo "ami_network_cidr = \"$AMI_NETWORK_CIDR\"" >> terraform.tfvars
  echo "ami_public_cidr = \"$AMI_PUBLIC_CIDR\"" >> terraform.tfvars
#  echo "test_vpc = \"$TEST_VPC\"" >> terraform.tfvars
#  echo "test_network_cidr = \"$TEST_NETWORK_CIDR\"" >> terraform.tfvars
#  echo "test_public_01_cidr = \"$TEST_PUBLIC_01_CIDR\"" >> terraform.tfvars
#  echo "test_public_02_cidr = \"$TEST_PUBLIC_02_CIDR\"" >> terraform.tfvars
#  echo "prod_vpc = \"$PROD_VPC\"" >> terraform.tfvars
#  echo "prod_network_cidr = \"$PROD_NETWORK_CIDR\"" >> terraform.tfvars
#  echo "prod_public_01_cidr = \"$PROD_PUBLIC_01_CIDR\"" >> terraform.tfvars
#  echo "prod_public_02_cidr = \"$PROD_PUBLIC_02_CIDR\"" >> terraform.tfvars
}

destroy_changes() {
  echo "----------------  Destroy changes  -------------------"
  terraform destroy -force

    #output AMI VPC
  shipctl post_resource_state_multi $OUT_AMI_VPC \
    "versionName='Version from build $BUILD_NUMBER' \
     STATUS='empty' "

#  #output TEST VPC
#  shipctl post_resource_state_multi $OUT_TEST_VPC \
#    "versionName='Version from build $BUILD_NUMBER' \
#     STATUS='empty' "
#
#  #output PROD VPC
#  shipctl post_resource_state_multi $OUT_PROD_VPC \
#    "versionName='Version from build $BUILD_NUMBER' \
#     STATUS='empty' "
}

apply_changes() {
  echo "----------------  Planning changes  -------------------"
  terraform plan

  echo "-----------------  Apply changes  ------------------"
  terraform apply

  #output AMI VPC
  shipctl post_resource_state_multi $OUT_AMI_VPC \
    "versionName='Version from build $BUILD_NUMBER' \
     STATUS='provisioned' \
     REGION=$REGION \
     BASE_ECS_AMI=$(terraform output base_ecs_ami) \
     AMI_VPC_ID=$(terraform output ami_vpc_id) \
     AMI_PUBLIC_SG_ID=$(terraform output ami_public_sg_id) \
     AMI_PUBLIC_SN_ID=$(terraform output ami_public_sn_id)"

#  #output TEST VPC
#  shipctl post_resource_state_multi $OUT_TEST_VPC \
#    "versionName='Version from build $BUILD_NUMBER' \
#     STATUS='provisioned' \
#     REGION=$REGION \
#     TEST_VPC_ID=$(terraform output test_vpc_id) \
#     TEST_PUBLIC_SG_ID=$(terraform output test_public_sg_id) \
#     TEST_PUBLIC_SN_01_ID=$(terraform output test_public_sn_01_id) \
#     TEST_PUBLIC_SN_02_ID=$(terraform output test_public_sn_02_id) "
#
#  #output PROD VPC
#  shipctl post_resource_state_multi $OUT_PROD_VPC \
#    "versionName='Version from build $BUILD_NUMBER' \
#     STATUS='provisioned' \
#     REGION=$REGION \
#     PROD_VPC_ID=$(terraform output prod_vpc_id) \
#     PROD_PUBLIC_SG_ID=$(terraform output prod_public_sg_id) \
#     PROD_PUBLIC_SN_01_ID=$(terraform output prod_public_sn_01_id) \
#     PROD_PUBLIC_SN_02_ID=$(terraform output prod_public_sn_02_id) "
}

main() {
  echo "----------------  Testing SSH  -------------------"
  eval `ssh-agent -s`
  ps -eaf | grep ssh
  which ssh-agent

  set_context

  if [ $ACTION = "create" ]; then
    apply_changes
  fi

  if [ $ACTION = "destroy" ]; then
    destroy_changes
  fi
}

main
