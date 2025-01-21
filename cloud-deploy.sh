#!/bin/bash

# Define constants
ADMIN_CREDS_FILE="/home/jeff/openstack_creds"
OUTPUT_RC_FILE="/home/jeff/openstack-credentials-file.rc"

# Update your system
echo "Updating system packages..."
sudo apt update -y && sudo apt dist-upgrade -y

# Install required packages
echo "Installing Git and other required packages..."
sudo apt install -y git python3-pip net-tools python3-openstackclient

# Clone OpenStack-Ansible repository and bootstrap Ansible
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
ADMIN_PASS=$(grep 'keystone_auth_admin_password:' /etc/openstack_deploy/user_secrets.yml | awk '{print $2}')

echo "Admin credentials:" > $ADMIN_CREDS_FILE
echo "$ADMIN_PASS" >> $ADMIN_CREDS_FILE
chmod 600 "$ADMIN_CREDS_FILE"
chown jeff:jeff "$ADMIN_CREDS_FILE"

echo "Admin credentials:" 
cat $ADMIN_CREDS_FILE

# Determine the OS_AUTH_URL using netstat
echo "Determining the OS_AUTH_URL from the Keystone service IP..."
AUTH_IP=$(netstat -tuln | grep ':5000' | awk '{print $4}' | grep '^172\.' | cut -d':' -f1)

if [[ -z "$AUTH_IP" ]]; then
    echo "Error: Unable to determine OS_AUTH_URL. Ensure Keystone is running and accessible on a 172.x.x.x address."
    exit 1
fi

OS_AUTH_URL="http://$AUTH_IP:5000/v3"

# Generate the OpenStack credentials file
echo "Creating the OpenStack credentials file ($OUTPUT_RC_FILE)..."
cat << EOF > "$OUTPUT_RC_FILE"
export OS_USERNAME=admin
export OS_PASSWORD=$ADMIN_PASS
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=$OS_AUTH_URL
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOF

# Set the appropriate permissions
chmod 600 "$OUTPUT_RC_FILE"
chown jeff:jeff "$OUTPUT_RC_FILE"

# Source the credentials file as user jeff
sudo -u jeff bash -c "source $OUTPUT_RC_FILE"

# Completion message
echo "OpenStack deployment and CLI setup completed successfully!"
echo "Admin credentials saved to $ADMIN_CREDS_FILE"
echo "Source the credentials file using: source $OUTPUT_RC_FILE"
