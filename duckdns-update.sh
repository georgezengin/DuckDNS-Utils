#!/bin/bash

# DuckDNS update script for WSL Ubuntu with syslog logging

# Configuration
DOMAINS="foo,bar"                 # comma-separated domains
TOKEN="<replace with your token>" # DuckDNS account token
IP=""                             # leave empty for auto-detect
DEBUG=false                       # set true for debug console output
DRYRUN=false                      # set true for dry run (no actual update)

log() {
  local msg="$1"
  if $DEBUG; then
    echo "[DEBUG] $msg"
  fi
  logger -t duckdns-update "$msg"
}

show_help() {
  cat << EOF
Usage: $0 -d domains -t token [-i ip] [-h] [-v] [-n]

Options:
  -d    Comma-separated DuckDNS domains (required)
  -t    DuckDNS token (required)
  -i    IP address to set (optional, auto-detected if omitted)
  -h    Show this help message
  -v    Enable debug output (console)
  -n    Dry run - show what would be done without updating

Example:
  $0 -d "foo,bar" -t "your-token" -v
EOF
}

# Parse args
while getopts "d:t:i:hvn" opt; do
  case "$opt" in
    d) DOMAINS=$OPTARG ;;
    t) TOKEN=$OPTARG ;;
    i) IP=$OPTARG ;;
    h) show_help; exit 0 ;;
    v) DEBUG=true ;;
    n) DRYRUN=true ;;
    *) show_help; exit 1 ;;
  esac
done

if [[ -z "$DOMAINS" || -z "$TOKEN" ]]; then
  echo "Error: Domains and Token are required."
  show_help
  exit 1
fi

# Auto-detect IP if not provided
if [[ -z "$IP" ]]; then
  IP=$(curl -sf https://api.ipify.org)
  if [[ $? -ne 0 || -z "$IP" ]]; then
    log "Failed to auto-detect external IP"
    IP=""
  else
    log "Auto-detected external IP: $IP"
  fi
fi

URL="https://www.duckdns.org/update?domains=${DOMAINS}&token=${TOKEN}&ip=${IP}"

if [[ "$DRYRUN" == true ]]; then
  echo "[DRY RUN] Would send update request to Duck DNS"
  echo "[DRY RUN] URL: $URL"
  exit 0
fi

log "Sending update request to DuckDNS: $URL"

RESPONSE=$(curl -sf "$URL")

log "Update response: $RESPONSE"

if [[ "$RESPONSE" == "OK" ]]; then
  log "DuckDNS update successful. Domains: $DOMAINS, IP: ${IP:-Auto-detected}"
elif [[ "$RESPONSE" == "KO" ]]; then
  log "DuckDNS update failed. Domains: $DOMAINS, IP: ${IP:-Auto-detected}"
  exit 1
else
  log "DuckDNS returned unexpected response: $RESPONSE. Domains: $DOMAINS, IP: ${IP:-Auto-detected}"
fi
