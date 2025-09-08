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
# try to detect memory via docker stats if docker is available
if [ -n "$SIGNAL_DOCKER_CONTAINER" ] && command -v docker >/dev/null 2>&1; then
  raw=$(docker stats --no-stream --format '{{.MemUsage}}' "$SIGNAL_DOCKER_CONTAINER" 2>/dev/null || true)
  # raw may look like: "27.34MiB / 1.944GiB"
  first=$(printf "%s" "$raw" | awk '{print $1}')
  if [ -n "$first" ]; then
    case "$first" in
      *KiB) val=$(printf "%s" "$first" | sed 's/KiB$//'); memory=$(awk "BEGIN {printf \"%d\", $val * 1024}") ;;
      *MiB) val=$(printf "%s" "$first" | sed 's/MiB$//'); memory=$(awk "BEGIN {printf \"%d\", $val * 1024 * 1024}") ;;
      *GiB) val=$(printf "%s" "$first" | sed 's/GiB$//'); memory=$(awk "BEGIN {printf \"%d\", $val * 1024 * 1024 * 1024}") ;;
      *kB)  val=$(printf "%s" "$first" | sed 's/kB$//'); memory=$(awk "BEGIN {printf \"%d\", $val * 1000}") ;;
      *MB)  val=$(printf "%s" "$first" | sed 's/MB$//');  memory=$(awk "BEGIN {printf \"%d\", $val * 1000 * 1000}") ;;
      *GB)  val=$(printf "%s" "$first" | sed 's/GB$//');  memory=$(awk "BEGIN {printf \"%d\", $val * 1000 * 1000 * 1000}") ;;
      *)    memory=$(printf "%s" "$first") ;;
    esac
  fi
fi

# memory threshold check
# Defaults: total memory 25GB, threshold percent 85% (configurable via SIGNAL_TOTAL_MEMORY_BYTES and SIGNAL_MEMORY_THRESHOLD_PERCENT)
TOTAL_MEMORY_BYTES="${SIGNAL_TOTAL_MEMORY_BYTES:-26843545600}"
THRESHOLD_PERCENT="${SIGNAL_MEMORY_THRESHOLD_PERCENT:-85}"

# compute threshold bytes
threshold_bytes=$(awk "BEGIN {printf \"%d\", ${TOTAL_MEMORY_BYTES} * ${THRESHOLD_PERCENT} / 100}")

if [ -n "$memory" ] && printf "%s" "$memory" | grep -Eq '^[0-9]+$'; then
  if [ "$memory" -gt "$threshold_bytes" ]; then
    exit_code=3
    failure_message="Memory ${memory} bytes exceeds threshold ${threshold_bytes} bytes (${THRESHOLD_PERCENT}%)"
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
