#!/usr/bin/env bash
set -euo pipefail

PORT_FILE="scripts/port.yaml"
DATASET_FILE="scripts/dataset_config.yaml"

episode=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --episode)
      episode="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$episode" ]]; then
  echo "Usage: $0 --episode <index>" >&2
  exit 1
fi

for file in "$PORT_FILE" "$DATASET_FILE"; do
  if [[ ! -f "$file" ]]; then
    echo "Missing $file" >&2
    exit 1
  fi
done

get_port() {
  local key="$1"
  local value

  value=$(sed -n "s/^${key}:[[:space:]]*//p" "$PORT_FILE" | tail -n 1)
  if [[ -z "$value" ]]; then
    echo "Missing port for ${key} in ${PORT_FILE}" >&2
    exit 1
  fi
  printf "%s" "$value"
}

get_dataset_value() {
  local key="$1"
  local value

  value=$(sed -n "s/^${key}:[[:space:]]*//p" "$DATASET_FILE" | tail -n 1)
  if [[ -z "$value" ]]; then
    echo "Missing ${key} in ${DATASET_FILE}" >&2
    exit 1
  fi
  value=${value#\"}
  value=${value%\"}
  printf "%s" "$value"
}

left_follower=$(get_port "left_follower")
right_follower=$(get_port "right_follower")

hf_user=$(get_dataset_value "hf_user")
repo=$(get_dataset_value "repo")

if [[ "$repo" != */* ]]; then
  repo_id="${hf_user}/${repo}"
else
  repo_id="$repo"
fi

lerobot-replay \
  --robot.type=bi_so101_follower \
  --robot.left_arm_port="${left_follower}" \
  --robot.right_arm_port="${right_follower}" \
  --robot.id=bimanual_follower \
  --dataset.repo_id="${repo_id}" \
  --dataset.episode="${episode}"
