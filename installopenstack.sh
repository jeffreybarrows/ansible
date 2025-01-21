#!/bin/bash

# Define variables
ADMIN_CREDS_FILE="/home/jeff/openstack_creds"

# Update your system
echo "Updating system packages..."
apt-get update && apt-get dist-upgrade -y

# Install Git
echo "Installing Git..."
apt-get install git -y

# Bootstrap Ansible and the required roles
echo "Cloning OpenStack-Ansible repository..."
git clone https://opendev.org/openstack/openstack-ansible /opt/openstack-ansible
cd /opt/openstack-ansible

# List all existing tags and check out the stable branch
echo "Listing all Git tags..."
git tag -l
echo "Checking out master branch..."
git checkout master

echo "Retrieving the latest tag..."
LATEST_TAG=$(git describe --abbrev=0 --tags)
echo "Latest tag found: $LATEST_TAG"
git checkout $LATEST_TAG

# Bootstrap Ansible and the required roles
echo "Bootstrapping Ansible and required roles..."
bash scripts/bootstrap-ansible.sh

# Default AIO configuration preparation
echo "Running AIO configuration preparation..."
bash scripts/bootstrap-aio.sh

# Run playbooks
echo "Running OpenStack playbooks..."
openstack-ansible openstack.osa.setup_hosts
openstack-ansible openstack.osa.setup_infrastructure
openstack-ansible openstack.osa.setup_openstack

# Get the admin password and save to a file
echo "Retrieving admin password..."
ADMIN_PASS=$( )

echo "Admin credentials:" > $ADMIN_CREDS_FILE
echo "$ADMIN_PASS" >> $ADMIN_CREDS_FILE
echo "Credentials saved to $ADMIN_CREDS_FILE"

echo "Admin credentials:" 
cat $ADMIN_CREDS_FILE

# Done
echo "OpenStack deployment complete."
