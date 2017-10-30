#!/bin/bash

DIST=${1}

function usage()
{
  echo Specify if you want to create a RHEL or Fedora ISO
  echo Example:
  echo   $(basename $0) fedora
  echo
  echo Please note, if you want to build a RHEL iso you need to supply username/password/subscription pool ID.
  exit 1
}

if [ "${DIST}" = "" ]
then
  usage
fi

if [ "${DIST}" = "rhel" ]
then
  RH_USERNAME=${RH_USERNAME:-default}
  RH_PASSWORD=${RH_PASSWORD:-default}
  RH_POOL_ID=${RH_POOL_ID:-default}

  if [ "${RH_PASSWORD}" = "default" ]
  then
    read -sp "Password: " RH_PASSWORD
  fi

  cp Dockerfile.rhel Dockerfile
  docker build -t isobuildenv --build-arg RH_USERNAME=$RH_USERNAME --build-arg RH_PASSWORD=$RH_PASSWORD --build-arg RH_POOL_ID=$RH_POOL_ID .
elif [ "${DIST}" = "fedora" ]
then
  FLAVOR=Workstation
  RELEASE=26
#  wget https://ftp.acc.umu.se/mirror/fedora/linux/releases/${RELEASE}/${FLAVOR}/x86_64/iso/Fedora-${FLAVOR}-Live-x86_64-${RELEASE}-1.5.iso
  cp Dockerfile.fedora Dockerfile
  docker build -t isobuildenv .
else
  usage
fi

docker run -v $(pwd)/../:/isobuildenv:z -it --rm isobuildenv bash
