# Overview

A rough framework to create a custom RHEL ISO which then can be expanded to do anything.

This allows you to create an ISO for usage in Virtual Machines or USB keys or whatever that can be disconnected from the rest of the world.

# Requirements

It requires you to do the setup of the ISO on a Linux-machine with Docker. Currently tested on Fedora/CentOS/RHEL. But should be fairly easy to expand to other platforms. Currently it requires to be run as root.

# How it works

## The scripts

### start_isobuildenv.sh
This sets create a Docker container which runs RHEL in which everything will be executed.

This requires that you setup some variables it needs to register the container
  export RH_USERNAME=myusername RH_POOL_ID=poolid

It will prompt you for the password.

Simply export the variables, then execute the script:
  ./start_isobuildenv.sh

Once built, you will be inside a container where you can execute create-iso.sh

### create-iso.sh

This is the actual workhorse, it will:
  * Download RHEL7 DVD
  * Extract the DVD
  * Insert a kickstart file
  * Clone any repositories you need
  * Insert all files you want to have on your ISO
  * Build the ISO image

Should be run inside a prepared machine with all the tools required. 

Execute with
  ./create-iso.sh

### (Optional) test_iso.sh

If you are on a host with KVM+libvirt running, just a small script to help for quicker test of the ISO. Will kill any VM named test, create a new VM called test and boot the ISO.
