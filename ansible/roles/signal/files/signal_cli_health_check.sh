#!/usr/bin/env sh
set -eu

# Health check script for signal-cli-rest-api
# Posts metrics to SIGNAL_MONITORING_URL (Oh Dear) as form fields

SIGNAL_API="${SIGNAL_API:-${signal_cli_rest_api_endpoint:-http://localhost:8080}}"
SIGNAL_MONITORING_URL="${SIGNAL_MONITORING_URL:-${signal_monitoring_url:-}}"
SIGNAL_DOCKER_CONTAINER="${SIGNAL_DOCKER_CONTAINER:-ansible-signal-1}"

start=$(date +%s.%N)

# probe endpoints (prefer accounts -> health)
# Treat any non-200 from /v1/accounts as a failure. Only fall back to /v1/health
# when /v1/accounts could not be reached (network error).
probe_ok=0
acct_code=""
# try accounts and capture http code; curl exits non-zero on network issues, but -s -o /dev/null -w '%{http_code}' still prints a code
acct_code=$(curl -s -o /dev/null -w '%{http_code}' "${SIGNAL_API}/v1/accounts" || echo "000")

is_2xx() {
  code="$1"
  # return success if numeric and in 200-299
  printf '%s' "$code" | grep -Eq '^[0-9]+$' || return 1
  [ "$code" -ge 200 ] && [ "$code" -lt 300 ]
}

if [ "$acct_code" = "000" ]; then
  # network/connectivity error talking to /v1/accounts; try /v1/health
  health_code=$(curl -s -o /dev/null -w '%{http_code}' "${SIGNAL_API}/v1/health" || echo "000")
  if is_2xx "$health_code"; then
    probe_ok=1
  else
    probe_ok=0
  fi
else
  # we reached /v1/accounts; accept any 2xx as healthy
  if is_2xx "$acct_code"; then
    probe_ok=1
  else
    probe_ok=0
  fi
fi

exit_code=0
failure_message="OK"
if [ "$probe_ok" -eq 0 ]; then
  # Prefer a descriptive message if /v1/accounts returned an error code
  if [ -n "$acct_code" ] && [ "$acct_code" != "000" ] && ! is_2xx "$acct_code"; then
    exit_code=2
    failure_message="Accounts endpoint returned HTTP ${acct_code}"
  else
    exit_code=2
    failure_message="Health endpoints unreachable"
  fi
fi

end=$(date +%s.%N)
runtime=$(awk "BEGIN {printf \"%.3f\", $end - $start}")

memory=""
total_memory=""
# Check system-wide memory usage from /proc/meminfo
if [ -r "/proc/meminfo" ]; then
  # Get total and available memory in kB from /proc/meminfo
  mem_total_kb=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo 2>/dev/null || echo "")
  mem_available_kb=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo 2>/dev/null || echo "")
  
  if [ -n "$mem_total_kb" ] && [ -n "$mem_available_kb" ]; then
    # Convert to bytes
    total_memory=$(awk "BEGIN {printf \"%d\", $mem_total_kb * 1024}")
    mem_available_bytes=$(awk "BEGIN {printf \"%d\", $mem_available_kb * 1024}")
    # Used memory = Total - Available
    memory=$(awk "BEGIN {printf \"%d\", $total_memory - $mem_available_bytes}")
  fi
fi

# memory threshold check
# Uses actual system memory if available, otherwise falls back to configured value
# Default threshold: 85% of total system memory
THRESHOLD_PERCENT="${SIGNAL_MEMORY_THRESHOLD_PERCENT:-85}"

# Use actual system memory if detected, otherwise fall back to configured value
if [ -n "$total_memory" ] && printf "%s" "$total_memory" | grep -Eq '^[0-9]+$'; then
  threshold_bytes=$(awk "BEGIN {printf \"%d\", ${total_memory} * ${THRESHOLD_PERCENT} / 100}")
else
  # Fallback to configured total memory (default: ~25GB)
  TOTAL_MEMORY_BYTES="${SIGNAL_TOTAL_MEMORY_BYTES:-26843545600}"
  threshold_bytes=$(awk "BEGIN {printf \"%d\", ${TOTAL_MEMORY_BYTES} * ${THRESHOLD_PERCENT} / 100}")
fi

if [ -n "$memory" ] && printf "%s" "$memory" | grep -Eq '^[0-9]+$'; then
  if [ "$memory" -gt "$threshold_bytes" ]; then
    exit_code=3
    memory_mb=$(awk "BEGIN {printf \"%.1f\", $memory / 1024 / 1024}")
    threshold_mb=$(awk "BEGIN {printf \"%.1f\", $threshold_bytes / 1024 / 1024}")
    failure_message="System memory ${memory_mb}MB exceeds threshold ${threshold_mb}MB (${THRESHOLD_PERCENT}%)"
  fi
fi

# Post to monitoring URL as form fields if configured
if [ -n "${SIGNAL_MONITORING_URL}" ]; then
  # send even if fields empty; Oh Dear accepts missing fields
  curl -sfS -X POST "${SIGNAL_MONITORING_URL}" \
    -F "memory=${memory}" \
    -F "runtime=${runtime}" \
    -F "exit_code=${exit_code}" \
    -F "failure_message=${failure_message}" || true
fi

exit ${exit_code}
