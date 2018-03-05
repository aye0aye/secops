#!/bin/bash -e

################### Description ###############################
# basic shell script to create swap space on the hosts
#
################### Verified Platforms ########################
# ubuntu 12.04
# ubuntu 14.04
###############################################################

main() {
#  sleep 60  #sleep so that we can avoid boot latency errors
#
  sudo apt-get update -y

  sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common -y
#
#  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
#
#  sudo add-apt-repository \
#   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
#   $(lsb_release -cs) \
#   stable"
#
#  sudo apt-get update
#
#  sudo apt-get --assume-yes install docker-ce
#
#  sudo docker pull hello-world

  echo $BE_IMG
  echo $BE_TAG
}

main
