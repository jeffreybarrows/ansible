#!/bin/bash

# Define constants
CREDS_FILE="/home/jeff/openstack_creds"
OUTPUT_RC_FILE="/home/jeff/openstack-credentials-file.rc"
VENV_DIR="/home/jeff/openstack_venv"

# Update and install required packages
echo "Updating the system and installing required packages..."
sudo apt update -y && sudo apt upgrade -y
sudo apt install -y python3-pip net-tools

# Install OpenStack CLI
echo "Installing the OpenStack CLI tool..."
sudo apt install python3-openstackclient -y

# Check if the credentials source file exists
if [[ ! -f "$CREDS_FILE" ]]; then
    echo "Error: Credentials source file ($CREDS_FILE) does not exist."
    deactivate
    exit 1
fi

# Extract the admin password from the credentials file
echo "Extracting admin password from the credentials file..."
ADMIN_PASSWORD=$(grep 'keystone_auth_admin_password:' "$CREDS_FILE" | awk '{print $2}')

if [[ -z "$ADMIN_PASSWORD" ]]; then
    echo "Error: Unable to extract admin password from $CREDS_FILE."
    deactivate
    exit 1
fi

# Determine the OS_AUTH_URL using netstat
echo "Determining the OS_AUTH_URL from the Keystone service IP..."
AUTH_IP=$(netstat -tuln | grep ':5000' | awk '{print $4}' | grep '^172\.' | cut -d':' -f1)

if [[ -z "$AUTH_IP" ]]; then
    echo "Error: Unable to determine OS_AUTH_URL. Ensure Keystone is running and accessible on a 172.x.x.x address."
    deactivate
    exit 1
fi

OS_AUTH_URL="http://$AUTH_IP:5000/v3"

# Generate the OpenStack credentials file
echo "Creating the OpenStack credentials file ($OUTPUT_RC_FILE)..."
cat << EOF > "$OUTPUT_RC_FILE"
export OS_USERNAME=admin
export OS_PASSWORD=$ADMIN_PASSWORD
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

# Deactivate the virtual environment
deactivate

echo "OpenStack CLI setup completed successfully!"
echo "Source the credentials file using: source $OUTPUT_RC_FILE"
echo "To use the OpenStack CLI, activate the virtual environment: source $VENV_DIR/bin/activate"
