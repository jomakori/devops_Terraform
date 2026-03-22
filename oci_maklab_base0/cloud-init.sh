#!/bin/bash
set -e

# Logging function for OCI Logging
log_to_oci() {
  local level=$1
  local message=$2
  local component="tailscale-setup"
  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  
  # Structured JSON log for OCI Logging
  cat << EOF >> /var/log/tailscale-setup.log
{"timestamp": "$timestamp", "level": "$level", "component": "$component", "message": "$message", "context": {"instance_id": "$(curl -s -H \"Authorization: Bearer Oracle\" -L http://169.254.169.254/opc/v2/instance/id 2>/dev/null || echo 'unknown')", "hostname": "$(hostname)"}}
EOF
  
  # Also log to syslog for local debugging
  logger -t "tailscale-setup" "[$level] $message"
}

# Function to check command success
check_command() {
  if [ $? -ne 0 ]; then
    log_to_oci "ERROR" "Command failed: $1"
    exit 1
  fi
}

# Start setup
log_to_oci "INFO" "Starting Tailscale setup on $(hostname)"

# 1. Update system and install prerequisites
log_to_oci "INFO" "Updating system packages"
dnf update -y
check_command "dnf update"

# 2. Install Tailscale
log_to_oci "INFO" "Installing Tailscale"
dnf config-manager --add-repo https://pkgs.tailscale.com/stable/fedora/tailscale.repo
dnf install -y tailscale
check_command "dnf install tailscale"

# 3. Install Doppler CLI for secret retrieval
log_to_oci "INFO" "Installing Doppler CLI"
curl -Ls https://cli.doppler.com/install.sh | sh -s -- --yes
check_command "install doppler cli"

# 4. Retrieve Tailscale auth key from Doppler
log_to_oci "INFO" "Retrieving Tailscale auth key from Doppler"
if [ -z "$DOPPLER_TOKEN" ]; then
  log_to_oci "ERROR" "DOPPLER_TOKEN environment variable not set"
  exit 1
fi

TAILSCALE_AUTH_KEY=$(doppler secrets get TAILSCALE_AUTH_KEY --plain --token="$DOPPLER_TOKEN" 2>/dev/null || echo "")
if [ -z "$TAILSCALE_AUTH_KEY" ]; then
  log_to_oci "ERROR" "Failed to retrieve TAILSCALE_AUTH_KEY from Doppler"
  exit 1
fi

log_to_oci "INFO" "Successfully retrieved Tailscale auth key"

# 5. Connect to Tailscale
log_to_oci "INFO" "Connecting to Tailscale network"
tailscale up --authkey="$TAILSCALE_AUTH_KEY" --hostname="$(hostname)" --advertise-exit-node --accept-routes
check_command "tailscale up"

# 6. Verify Tailscale connection
log_to_oci "INFO" "Verifying Tailscale connection"
sleep 10 # Wait for connection to establish

if tailscale status | grep -q "Connected"; then
  TAILSCALE_IP=$(tailscale ip -4)
  log_to_oci "INFO" "Tailscale connected successfully. IP: $TAILSCALE_IP"
  
  # Log connection details
  echo "Tailscale Status:" >> /var/log/tailscale-setup.log
  tailscale status >> /var/log/tailscale-setup.log
  echo "Tailscale IPs:" >> /var/log/tailscale-setup.log
  tailscale ip -4 >> /var/log/tailscale-setup.log
  tailscale ip -6 >> /var/log/tailscale-setup.log
else
  log_to_oci "ERROR" "Tailscale connection failed"
  echo "Tailscale status output:" >> /var/log/tailscale-setup.log
  tailscale status >> /var/log/tailscale-setup.log
  exit 1
fi

# 7. Enable IP forwarding for subnet routes (if needed)
log_to_oci "INFO" "Enabling IP forwarding"
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv6.conf.all.forwarding=1
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf

# 8. Configure firewall to allow Tailscale traffic
log_to_oci "INFO" "Configuring firewall for Tailscale"
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="100.64.0.0/10" accept'
firewall-cmd --permanent --add-rich-rule='rule family="ipv6" source address="fd7a:115c:a1e0::/48" accept'
firewall-cmd --reload
check_command "firewall configuration"

# 9. Create systemd service for monitoring
log_to_oci "INFO" "Creating Tailscale monitoring service"
cat << 'EOF' > /etc/systemd/system/tailscale-monitor.service
[Unit]
Description=Tailscale Connection Monitor
After=tailscale.service
Requires=tailscale.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/bash -c 'if tailscale status | grep -q "Connected"; then echo "Tailscale connected"; else echo "Tailscale not connected"; exit 1; fi'
ExecStartPost=/bin/bash -c 'logger -t "tailscale-monitor" "Tailscale connection verified"'

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable tailscale-monitor.service

# 10. Create log rotation for Tailscale logs
log_to_oci "INFO" "Setting up log rotation"
cat << 'EOF' > /etc/logrotate.d/tailscale-setup
/var/log/tailscale-setup.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0644 root root
}
EOF

# 11. Final verification
log_to_oci "INFO" "Running final verification"
if systemctl is-active --quiet tailscale; then
  log_to_oci "INFO" "Tailscale service is active"
else
  log_to_oci "ERROR" "Tailscale service is not active"
  exit 1
fi

# 12. Success message
log_to_oci "INFO" "Tailscale setup completed successfully on $(hostname)"
echo "==========================================" >> /var/log/tailscale-setup.log
echo "SETUP COMPLETED SUCCESSFULLY" >> /var/log/tailscale-setup.log
echo "Timestamp: $(date)" >> /var/log/tailscale-setup.log
echo "Hostname: $(hostname)" >> /var/log/tailscale-setup.log
echo "Tailscale IP: $(tailscale ip -4)" >> /var/log/tailscale-setup.log
echo "==========================================" >> /var/log/tailscale-setup.log

# Print success message to console
echo "Tailscale setup completed successfully!"
echo "Tailscale IP: $(tailscale ip -4)"
echo "Logs available at: /var/log/tailscale-setup.log"
echo "Check OCI Logging for structured JSON logs"
