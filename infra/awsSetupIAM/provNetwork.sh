#!/bin/bash -e

export ACTION=$1
export STATE_RES="netw_tf_state"
export RES_AWS_CREDS="demo_aws_cli"
export RES_AWS_PEM="demo_aws_pem"
export OUT_AMI_VPC="ami_vpc_info"
export OUT_TEST_VPC="test_vpc_info"
export OUT_PROD_VPC="prod_vpc_info"

export TF_STATEFILE="terraform.tfstate"

# Now get AWS keys
export AWS_ACCESS_KEY_ID=$(shipctl get_integration_resource_field $RES_AWS_CREDS aws_access_key_id)
export AWS_SECRET_ACCESS_KEY=$(shipctl get_integration_resource_field $RES_AWS_CREDS aws_secret_access_key)

set_context(){
  echo "RES_AWS_CREDS=$RES_AWS_CREDS"
  echo "RES_AWS_PEM=$RES_AWS_PEM"

  echo "AWS_ACCESS_KEY_ID=${#AWS_ACCESS_KEY_ID}" #print only length not value
  echo "AWS_SECRET_ACCESS_KEY=${#AWS_SECRET_ACCESS_KEY}" #print only length not value

  # This restores the terraform state file
  shipctl ship_resource_copy_file_from_state $STATE_RES $TF_STATEFILE .

  # This gets the PEM key for SSH into the machines
  shipctl ship_resource_get_integration $RES_AWS_PEM key > ../demo-key.pem
  chmod 600 ../demo-key.pem

  # now setup the variables based on context
  # naming the file terraform.tfvars makes terraform automatically load it

  echo "aws_access_key_id = \"$AWS_ACCESS_KEY_ID\"" > terraform.tfvars
  echo "aws_secret_access_key = \"$AWS_SECRET_ACCESS_KEY\"" >> terraform.tfvars
  echo "region = \"$REGION\"" >> terraform.tfvars
  echo "ami_vpc = \"$AMI_VPC\"" >> terraform.tfvars
  echo "ami_network_cidr = \"$AMI_NETWORK_CIDR\"" >> terraform.tfvars
  echo "ami_public_cidr = \"$AMI_PUBLIC_CIDR\"" >> terraform.tfvars
  echo "test_vpc = \"$TEST_VPC\"" >> terraform.tfvars
  echo "test_network_cidr = \"$TEST_NETWORK_CIDR\"" >> terraform.tfvars
  echo "test_public_01_cidr = \"$TEST_PUBLIC_01_CIDR\"" >> terraform.tfvars
  echo "test_public_02_cidr = \"$TEST_PUBLIC_02_CIDR\"" >> terraform.tfvars
  echo "prod_vpc = \"$PROD_VPC\"" >> terraform.tfvars
  echo "prod_network_cidr = \"$PROD_NETWORK_CIDR\"" >> terraform.tfvars
  echo "prod_public_01_cidr = \"$PROD_PUBLIC_01_CIDR\"" >> terraform.tfvars
  echo "prod_public_02_cidr = \"$PROD_PUBLIC_02_CIDR\"" >> terraform.tfvars
}

destroy_changes() {
  echo "----------------  Destroy changes  -------------------"
  terraform destroy -force
}

apply_changes() {
  echo "----------------  Planning changes  -------------------"
  terraform plan

  echo "-----------------  Apply changes  ------------------"
#  terraform apply

  #output AMI VPC
  shipctl ship_resource_post_state $OUT_AMI_VPC versionName \
    "Version from build $BUILD_NUMBER"
  shipctl ship_resource_put_state $OUT_AMI_VPC REGION $REGION
  shipctl ship_resource_put_state $OUT_AMI_VPC BASE_ECS_AMI \
    $(terraform output base_ecs_ami)
  shipctl ship_resource_put_state $OUT_AMI_VPC AMI_VPC_ID \
    $(terraform output ami_vpc_id)
  shipctl ship_resource_put_state $OUT_AMI_VPC AMI_PUBLIC_SG_ID \
    $(terraform output ami_public_sg_id)
  shipctl ship_resource_put_state $OUT_AMI_VPC AMI_PUBLIC_SN_ID \
    $(terraform output ami_public_sn_id)

  #output TEST VPC
  shipctl ship_resource_post_state $OUT_TEST_VPC versionName \
    "Version from build $BUILD_NUMBER"
  shipctl ship_resource_put_state $OUT_TEST_VPC REGION $REGION
  shipctl ship_resource_put_state $OUT_TEST_VPC TEST_VPC_ID \
    $(terraform output test_vpc_id)
  shipctl ship_resource_put_state $OUT_TEST_VPC TEST_PUBLIC_SG_ID \
    $(terraform output test_public_sg_id)
  shipctl ship_resource_put_state $OUT_TEST_VPC TEST_PUBLIC_SN_01_ID \
    $(terraform output test_public_sn_01_id)
  shipctl ship_resource_put_state $OUT_TEST_VPC TEST_PUBLIC_SN_02_ID \
    $(terraform output test_public_sn_02_id)

  #output PROD VPC
  shipctl ship_resource_post_state $OUT_PROD_VPC versionName \
    "Version from build $BUILD_NUMBER"
  shipctl ship_resource_put_state $OUT_PROD_VPC REGION $REGION
  shipctl ship_resource_put_state $OUT_PROD_VPC PROD_VPC_ID \
    $(terraform output prod_vpc_id)
  shipctl ship_resource_put_state $OUT_PROD_VPC PROD_PUBLIC_SG_ID \
    $(terraform output prod_public_sg_id)
  shipctl ship_resource_put_state $OUT_PROD_VPC PROD_PUBLIC_SN_01_ID \
    $(terraform output prod_public_sn_01_id)
  shipctl ship_resource_put_state $OUT_PROD_VPC PROD_PUBLIC_SN_02_ID \
    $(terraform output prod_public_sn_02_id)
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
