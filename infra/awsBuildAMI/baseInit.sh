#!/bin/bash -e

################### Description ###############################
# basic shell script to create swap space on the hosts
#
################### Verified Platforms ########################
# ubuntu 12.04
# ubuntu 14.04
###############################################################

main() {
  sleep 60  #sleep so that we can avoid boot latency errors

  sudo -y apt-get update

  sudo -y apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

  sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

  sudo apt-get update

  sudo apt-get install docker-ce

  sudo docker pull hello-world
}

main
