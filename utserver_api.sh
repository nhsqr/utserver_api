#!/usr/bin/env bash
# utserver_api - Modern Bash client for µTorrent / uTorrent WebUI API
# Original 2017 script by nhsqr, fully rewritten 2026
#
# Requires: bash >= 4, curl, jq
#
# License: GPL-3.0

set -euo pipefail

VERSION="2.0.0"
SCRIPT_NAME="$(basename "$0")"

# ---------------------------------------------------------------------------
# Defaults & configuration
# ---------------------------------------------------------------------------
UTORRENT_URL="${UTORRENT_URL:-}"
UTORRENT_USER="${UTORRENT_USER:-}"
UTORRENT_PASS="${UTORRENT_PASS:-}"
CONFIG_FILE="${UTORRENT_CONFIG:-}"

# Runtime
COOKIE_JAR=""
TOKEN=""
TMPDIR=""
LIST_CACHE=""
JSON_OUTPUT=0
VERBOSE=0

# Field index map (0-based) for the classic list=1 response
declare -A FIELD_INDEX=(
  [hash]=0
  [statusint]=1
  [name]=2
  [size]=3
  [percent]=4
  [downloaded]=5
  [uploaded]=6
  [ratio]=7
  [upspeed]=8
  [downspeed]=9
  [eta]=10
  [label]=11
  [peercon]=12
  [peerswarm]=13
  [seedcon]=14
  [seedswarm]=15
  [availability]=16
  [queue]=17
  [remaining]=18
  [download_url]=19
  [rss_url]=20
  [status]=21          # human status message
  [stream_id]=22
  [date_added]=23
  [date_completed]=24
  [app_update_url]=25
  [folder]=26          # save path
)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
die()  { echo "Error: $*" >&2; exit 1; }
info() { [[ $VERBOSE -eq 1 ]] && echo "$*" >&2 || true; }

cleanup() {
  [[ -n "${COOKIE_JAR:-}" && -f "$COOKIE_JAR" ]] && rm -f "$COOKIE_JAR"
  [[ -n "${TMPDIR:-}" && -d "$TMPDIR" ]] && rm -rf "$TMPDIR"
}
trap cleanup EXIT

usage() {
  cat <<EOF
$SCRIPT_NAME v$VERSION - µTorrent / uTorrent WebUI API client (Bash)

Usage:
  $SCRIPT_NAME [options] <command> [arguments]

Global options:
  -c, --config FILE   Config file (default: ~/.config/utserver_api.conf)
  -j, --json          Output machine-readable JSON where applicable
  -v, --verbose       Verbose messages
  -h, --help          Show this help
  --version           Show version

Commands:
  list [--json]                 List all torrents (table or JSON)
  get  <field> <id|all>         Get a field (name, size, percent, status, ...)
  set  <action|prop=value> <id> Start/stop/pause/... or set property
  start|stop|pause|unpause|forcestart|recheck|remove|removedata <id>
  add  <magnet-or-url>           Add torrent by magnet link or .torrent URL
  props <id>                    Show detailed properties for a torrent
  status <int>                  Decode a status bitfield integer

  id can be:
    - 1-based index from the current list
    - full or partial info-hash (case-insensitive)

Supported get fields:
  hash statusint name size percent downloaded uploaded ratio
  upspeed downspeed eta label peercon peerswarm seedcon seedswarm
  availability queue remaining status folder download_url

Config file example (~/.config/utserver_api.conf):
  UTORRENT_URL="http://127.0.0.1:8080/gui/"
  UTORRENT_USER="admin"
  UTORRENT_PASS="secret"

Environment variables override the config file.
EOF
}

load_config() {
  local candidates=()
  [[ -n "$CONFIG_FILE" ]] && candidates+=("$CONFIG_FILE")
  candidates+=("${XDG_CONFIG_HOME:-$HOME/.config}/utserver_api.conf")
  candidates+=("$HOME/.utserver_api.conf")
  candidates+=("/etc/utserver_api.conf")

  local f
  for f in "${candidates[@]}"; do
    if [[ -f "$f" && -r "$f" ]]; then
      info "Loading config: $f"
      # shellcheck source=/dev/null
      source "$f"
      break
    fi
  done

  # Final validation
  [[ -z "$UTORRENT_URL" ]]  && die "UTORRENT_URL is not set (config or environment)"
  [[ -z "$UTORRENT_USER" ]] && die "UTORRENT_USER is not set"
  [[ -z "$UTORRENT_PASS" ]] && die "UTORRENT_PASS is not set"

  # Ensure trailing slash
  UTORRENT_URL="${UTORRENT_URL%/}/"
}

# ---------------------------------------------------------------------------
# API layer
# ---------------------------------------------------------------------------
auth() {
  TMPDIR=$(mktemp -d)
  COOKIE_JAR="$TMPDIR/cookies.txt"
  LIST_CACHE="$TMPDIR/list.json"

  local token_html
  token_html=$(curl -sS -u "${UTORRENT_USER}:${UTORRENT_PASS}" \
    -c "$COOKIE_JAR" -b "$COOKIE_JAR" \
    "${UTORRENT_URL}token.html" 2>/dev/null) || die "Failed to contact $UTORRENT_URL"

  TOKEN=$(echo "$token_html" | sed -E 's/.*<div[^>]*id=["'\'']token["'\''][^>]*>([^<]+)<.*/\1/; t; s/.*>([^<]+)<.*/\1/' | tr -d '[:space:]')

  if [[ -z "$TOKEN" || "$TOKEN" == *"<"* ]]; then
    # Fallback: strip all tags
    TOKEN=$(echo "$token_html" | sed 's/<[^>]*>//g' | tr -d '[:space:]')
  fi

  [[ -z "$TOKEN" ]] && die "Could not obtain authentication token (check credentials / WebUI)"
  info "Authenticated, token obtained"
}

api_get() {
  # Usage: api_get "param1=value&param2=value"
  local params="$1"
  curl -sS -u "${UTORRENT_USER}:${UTORRENT_PASS}" \
    -b "$COOKIE_JAR" -c "$COOKIE_JAR" \
    -G "${UTORRENT_URL}" \
    --data-urlencode "token=${TOKEN}" \
    --data-urlencode "${params}" \
    ${params:+ } 2>/dev/null
}

# Better: build query properly
api_call() {
  local -a args=()
  local k v
  for pair in "$@"; do
    k="${pair%%=*}"
    v="${pair#*=}"
    args+=(--data-urlencode "${k}=${v}")
  done

  curl -sS -u "${UTORRENT_USER}:${UTORRENT_PASS}" \
    -b "$COOKIE_JAR" -c "$COOKIE_JAR" \
    -G "${UTORRENT_URL}" \
    --data-urlencode "token=${TOKEN}" \
    "${args[@]}" 2>/dev/null
}

fetch_list() {
  if [[ ! -f "$LIST_CACHE" ]]; then
    local raw
    raw=$(api_call "list=1") || die "Failed to fetch torrent list"
    echo "$raw" > "$LIST_CACHE"
  fi
  cat "$LIST_CACHE"
}

# ---------------------------------------------------------------------------
# Status bitfield decoder
# ---------------------------------------------------------------------------
decode_status() {
  local s=$1
  local flags=()
  (( s & 1   )) && flags+=("Started")
  (( s & 2   )) && flags+=("Checking")
  (( s & 4   )) && flags+=("StartAfterCheck")
  (( s & 8   )) && flags+=("Checked")
  (( s & 16  )) && flags+=("Error")
  (( s & 32  )) && flags+=("Paused")
  (( s & 64  )) && flags+=("Queued")
  (( s & 128 )) && flags+=("Loaded")
  if ((${#flags[@]})); then
    local IFS=+
    echo "${flags[*]}"
  else
    echo "Unknown($s)"
  fi
}

# ---------------------------------------------------------------------------
# Resolve id (index or hash) → full hash + 0-based array index
# ---------------------------------------------------------------------------
resolve_id() {
  local id="$1"
  local list json_hash idx

  list=$(fetch_list)

  # Try as 1-based index first
  if [[ "$id" =~ ^[0-9]+$ ]]; then
    idx=$((id - 1))
    json_hash=$(echo "$list" | jq -r --argjson i "$idx" '.torrents[$i][0] // empty')
    if [[ -n "$json_hash" && "$json_hash" != "null" ]]; then
      echo "$json_hash $idx"
      return 0
    fi
  fi

  # Try as (partial) hash
  local upper
  upper=$(echo "$id" | tr '[:lower:]' '[:upper:]')
  local result
  result=$(echo "$list" | jq -r --arg h "$upper" '
    .torrents
    | to_entries[]
    | select(.value[0] | ascii_upcase | startswith($h) or . == $h)
    | "\(.value[0]) \(.key)"
    ' | head -n1)

  if [[ -n "$result" ]]; then
    echo "$result"
    return 0
  fi

  die "Torrent not found: $id"
}

# ---------------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------------
cmd_list() {
  local list
  list=$(fetch_list)

  if [[ $JSON_OUTPUT -eq 1 ]]; then
    echo "$list" | jq '{build, label, torrents: [.torrents[] | {
      hash: .[0],
      status: .[1],
      status_text: (.[1] | tostring),
      name: .[2],
      size: .[3],
      percent: (.[4] / 10),
      downloaded: .[5],
      uploaded: .[6],
      ratio: (.[7] / 1000),
      upspeed: .[8],
      downspeed: .[9],
      eta: .[10],
      label: .[11],
      peers: .[12],
      seeds: .[14],
      queue: .[17],
      remaining: .[18],
      status_msg: .[21],
      folder: .[26]
    }]}'
    return
  fi

  # Human table
  echo "$list" | jq -r '
    .torrents
    | to_entries[]
    | [
        (.key + 1 | tostring),
        .value[0][0:8],
        (.[value][4] / 10 | floor | tostring) + "%",
        (.[value][3] / 1048576 | floor | tostring) + "M",
        .value[2]
      ]
    | @tsv
  ' | column -t -s $'\t' -N "#,HASH,%,SIZE,NAME" 2>/dev/null || {
    # Fallback without column
    printf "%-4s %-10s %-5s %-8s %s\n" "#" "HASH" "%" "SIZE" "NAME"
    echo "$list" | jq -r '
      .torrents
      | to_entries[]
      | [
          (.key + 1),
          .value[0][0:8],
          ((.[value][4] / 10 | floor) | tostring) + "%",
          ((.[value][3] / 1048576 | floor) | tostring) + "M",
          .value[2]
        ]
      | @tsv
    ' | while IFS=$'\t' read -r num hash pct size name; do
      printf "%-4s %-10s %-5s %-8s %s\n" "$num" "$hash" "$pct" "$size" "$name"
    done
  }
}

cmd_get() {
  local field="$1"
  local id="$2"

  [[ -z "$field" || -z "$id" ]] && die "Usage: get <field> <id|all>"

  local idx
  if [[ -z "${FIELD_INDEX[$field]+x}" ]]; then
    die "Unknown field: $field. See --help"
  fi
  idx=${FIELD_INDEX[$field]}

  local list
  list=$(fetch_list)

  if [[ "$id" == "all" ]]; then
    if [[ $JSON_OUTPUT -eq 1 ]]; then
      echo "$list" | jq -r --argjson i "$idx" '[.torrents[][$i]]'
    else
      echo "$list" | jq -r --argjson i "$idx" '.torrents[][$i]'
    fi
    return
  fi

  local resolved hash arr_idx
  resolved=$(resolve_id "$id")
  hash=${resolved%% *}
  arr_idx=${resolved##* }

  local value
  value=$(echo "$list" | jq -r --argjson i "$arr_idx" --argjson f "$idx" '.torrents[$i][$f]')

  if [[ "$field" == "statusint" ]]; then
    echo "$value"
  elif [[ "$field" == "percent" ]]; then
    # show as real percent
    awk -v v="$value" 'BEGIN{printf "%.1f\n", v/10}'
  elif [[ "$field" == "ratio" ]]; then
    awk -v v="$value" 'BEGIN{printf "%.3f\n", v/1000}'
  else
    echo "$value"
  fi
}

cmd_set() {
  local action_or_prop="$1"
  local id="$2"

  [[ -z "$action_or_prop" || -z "$id" ]] && die "Usage: set <action|prop=value> <id>"

  local resolved hash
  resolved=$(resolve_id "$id")
  hash=${resolved%% *}

  local property value
  if [[ "$action_or_prop" == *=* ]]; then
    property="${action_or_prop%%=*}"
    value="${action_or_prop#*=}"
    case "$property" in
      label|ulrate|dlrate|superseed|seed_override|seed_ratio|seed_time|ulslots)
        api_call "action=setprops" "hash=$hash" "s=$property" "v=$value" >/dev/null \
          || die "setprops failed"
        echo "OK: $property=$value set on $hash"
        ;;
      *)
        die "Unsupported property: $property"
        ;;
    esac
  else
    case "$action_or_prop" in
      start|stop|pause|unpause|forcestart|recheck|remove|removedata|queuebottom|queuedown|queuetop|queueup)
        api_call "action=$action_or_prop" "hash=$hash" >/dev/null \
          || die "action $action_or_prop failed"
        echo "OK: $action_or_prop on $hash"
        ;;
      *)
        die "Unknown action: $action_or_prop"
        ;;
    esac
  fi
}

cmd_action() {
  # Convenience wrappers: start|stop|...
  local action="$1"
  shift
  cmd_set "$action" "$@"
}

cmd_add() {
  local url="$1"
  [[ -z "$url" ]] && die "Usage: add <magnet-or-url>"

  local result
  result=$(api_call "action=add-url" "s=$url") || die "add-url failed"

  if echo "$result" | jq -e '.error' >/dev/null 2>&1; then
    die "Server returned error: $(echo "$result" | jq -r '.error')"
  fi
  echo "OK: torrent added"
}

cmd_props() {
  local id="$1"
  [[ -z "$id" ]] && die "Usage: props <id>"

  local resolved hash
  resolved=$(resolve_id "$id")
  hash=${resolved%% *}

  local props
  props=$(api_call "action=getprops" "hash=$hash") || die "getprops failed"

  if [[ $JSON_OUTPUT -eq 1 ]]; then
    echo "$props" | jq .
  else
    echo "$props" | jq -r '.props[0] | to_entries[] | "\(.key): \(.value)"'
  fi
}

cmd_status() {
  local s="$1"
  [[ -z "$s" || ! "$s" =~ ^[0-9]+$ ]] && die "Usage: status <integer>"
  decode_status "$s"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
  # Parse global options
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -c|--config)
        CONFIG_FILE="$2"
        shift 2
        ;;
      -j|--json)
        JSON_OUTPUT=1
        shift
        ;;
      -v|--verbose)
        VERBOSE=1
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      --version)
        echo "$SCRIPT_NAME $VERSION"
        exit 0
        ;;
      --)
        shift
        break
        ;;
      -*)
        die "Unknown option: $1"
        ;;
      *)
        break
        ;;
    esac
  done

  [[ $# -eq 0 ]] && { usage; exit 1; }

  local cmd="$1"
  shift

  load_config
  auth

  case "$cmd" in
    list)          cmd_list "$@" ;;
    get)           cmd_get "$@" ;;
    set)           cmd_set "$@" ;;
    start|stop|pause|unpause|forcestart|recheck|remove|removedata)
                   cmd_action "$cmd" "$@" ;;
    add)           cmd_add "$@" ;;
    props)         cmd_props "$@" ;;
    status)        cmd_status "$@" ;;
    # Legacy compatibility
    --get|-g)      cmd_get "$@" ;;
    --set|-s)      cmd_set "$@" ;;
    --help|-h)     usage ;;
    *)
      die "Unknown command: $cmd. Try --help"
      ;;
  esac
}

main "$@"
