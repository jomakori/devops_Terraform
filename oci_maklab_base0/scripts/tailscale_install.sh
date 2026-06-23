#!/bin/bash
# Tailscale installation script for OCI VMs with OCI Logging integration
# Logs are written to local file and picked up by OCI Unified Monitoring Agent

set -euo pipefail

LOG_FILE="/var/log/tailscale_install.log"
LOG_DIR="/var/log/tailscale"
MAX_RETRIES=3
TAILSCALE_AUTH_KEY="${TAILSCALE_AUTH_KEY:-}"
HOSTNAME="${HOSTNAME:-$(hostname)}"

# Ensure log directory exists for OCI Logging agent pickup
mkdir -p "$LOG_DIR"

# Structured logging function for OCI Logging compatibility
log() {
    local level="${1:-INFO}"
    shift
    local message="$*"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # JSON-structured log for OCI Logging Service parsing
    local json_log="{\"timestamp\":\"$timestamp\",\"level\":\"$level\",\"component\":\"tailscale\",\"hostname\":\"$HOSTNAME\",\"message\":\"$message\"}"
    
    # Write to both log files (human-readable and JSON)
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
    echo "$json_log" >> "$LOG_DIR/install.json"
}

log_info() {
    log "INFO" "$@"
}

log_error() {
    log "ERROR" "$@"
}

log_success() {
    log "SUCCESS" "$@"
}

# Wait for network (max 60 seconds)
wait_for_network() {
    for i in $(seq 1 30); do
        if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
            log_info "Network ready"
            return 0
        fi
        sleep 2
    done
    log_error "Network timeout after 60 seconds"
    return 1
}

# Install Tailscale via official repo
install_tailscale() {
    if command -v tailscale >/dev/null 2>&1; then
        log_info "Tailscale already installed"
        return 0
    fi

    log_info "Installing Tailscale..."
    curl -fsSL https://pkgs.tailscale.com/stable/rhel/9/tailscale.repo -o /etc/yum.repos.d/tailscale.repo
    dnf install -y tailscale
    systemctl enable --now tailscaled
    log_info "Tailscale installed successfully"
}

# Authenticate with retry
authenticate() {
    if [ -z "$TAILSCALE_AUTH_KEY" ]; then
        log_error "TAILSCALE_AUTH_KEY not set"
        return 1
    fi

    for attempt in $(seq 1 $MAX_RETRIES); do
        log_info "Authentication attempt $attempt/$MAX_RETRIES"
        if tailscale up --auth-key "$TAILSCALE_AUTH_KEY" --hostname "$HOSTNAME" --ssh --accept-routes --reset 2>&1 | tee -a "$LOG_FILE"; then
            if tailscale status >/dev/null 2>&1; then
                local tailscale_ip=$(tailscale ip -4 2>/dev/null || echo 'N/A')
                log_success "Tailscale connected - IP: $tailscale_ip"
                return 0
            fi
        fi
        sleep 5
    done

    log_error "Authentication failed after $MAX_RETRIES attempts"
    return 1
}

# Sync logs to OCI Logging directory for agent pickup
sync_logs() {
    cp "$LOG_FILE" "$LOG_DIR/install.log" 2>/dev/null || true
    log_info "Logs synced to $LOG_DIR for OCI Logging agent"
}

# Main
log_info "Starting Tailscale installation for $HOSTNAME"
wait_for_network || { sync_logs; exit 1; }
install_tailscale || { sync_logs; exit 1; }
authenticate || { sync_logs; exit 1; }
log_success "Installation complete"
sync_logs
