#!/usr/bin/env bash
set -euo pipefail

PORT_FILE="scripts/port.yaml"
CAMERA_FILE="scripts/camera.yaml"
DATASET_FILE="scripts/dataset_config.yaml"

resume_requested=false
reset_requested=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --resume)
      resume_requested=true
      shift
      ;;
    --reset)
      reset_requested=true
      shift
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

if $resume_requested && $reset_requested; then
  echo "Cannot use --resume and --reset together." >&2
  exit 1
fi

for file in "$PORT_FILE" "$CAMERA_FILE" "$DATASET_FILE"; do
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

get_cam_value() {
  local section="$1"
  local key="$2"
  local value

  value=$(awk -v section="$section" -v key="$key" '
    BEGIN { current = "" }
    /^[^[:space:]]/ {
      split($1, a, ":");
      current = a[1];
    }
    current == section && $1 == key ":" { print $2 }
  ' "$CAMERA_FILE" | tail -n 1)

  if [[ -z "$value" ]]; then
    echo "Missing ${section}.${key} in ${CAMERA_FILE}" >&2
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
left_leader=$(get_port "left_leader")
right_leader=$(get_port "right_leader")

front_type=$(get_cam_value "front" "type")
front_index=$(get_cam_value "front" "index_or_path")
front_width=$(get_cam_value "front" "width")
front_height=$(get_cam_value "front" "height")
front_fps=$(get_cam_value "front" "fps")

wrist_type=$(get_cam_value "wrist" "type")
wrist_index=$(get_cam_value "wrist" "index_or_path")
wrist_width=$(get_cam_value "wrist" "width")
wrist_height=$(get_cam_value "wrist" "height")
wrist_fps=$(get_cam_value "wrist" "fps")

wrist2_type=$(get_cam_value "wrist2" "type")
wrist2_index=$(get_cam_value "wrist2" "index_or_path")
wrist2_width=$(get_cam_value "wrist2" "width")
wrist2_height=$(get_cam_value "wrist2" "height")
wrist2_fps=$(get_cam_value "wrist2" "fps")

hf_user=$(get_dataset_value "hf_user")
repo=$(get_dataset_value "repo")
num_episodes=$(get_dataset_value "num_eposides")
single_task=$(get_dataset_value "single_task")
push_to_hub=$(get_dataset_value "push_to_hub")
episode_time_s=$(get_dataset_value "episode_time_s")
reset_time_s=$(get_dataset_value "reset_time_s")

if [[ "$repo" != */* ]]; then
  repo_id="${hf_user}/${repo}"
else
  repo_id="$repo"
fi

hf_home="${HF_HOME:-$HOME/.cache/huggingface}"
default_root="${hf_home}/lerobot/${repo_id}"
resume_flag=""

if $reset_requested; then
  if [[ -d "$default_root" ]]; then
    echo "Reset requested. Removing ${default_root}." >&2
    rm -rf "$default_root"
  fi
else
  if $resume_requested; then
    if [[ ! -d "$default_root" ]]; then
      echo "Resume requested but dataset not found at ${default_root}." >&2
      exit 1
    fi
    resume_flag="--resume=true"
  else
    if [[ -d "$default_root" ]]; then
      echo "Dataset already exists at ${default_root}. Use --resume or --reset." >&2
      exit 1
    fi
  fi
fi

cameras="{ front: { type: ${front_type}, index_or_path: ${front_index}, width: ${front_width}, height: ${front_height}, fps: ${front_fps} }, left_wrist: { type: ${wrist_type}, index_or_path: ${wrist_index}, width: ${wrist_width}, height: ${wrist_height}, fps: ${wrist_fps} }, right_wrist: { type: ${wrist2_type}, index_or_path: ${wrist2_index}, width: ${wrist2_width}, height: ${wrist2_height}, fps: ${wrist2_fps} } }"

push_flag="--dataset.push_to_hub=$(printf "%s" "$push_to_hub" | tr 'A-Z' 'a-z')"
episode_time_flag="--dataset.episode_time_s=${episode_time_s}"
reset_time_flag="--dataset.reset_time_s=${reset_time_s}"

lerobot-record \
  --robot.type=bi_so101_follower \
  --robot.left_arm_port="${left_follower}" \
  --robot.right_arm_port="${right_follower}" \
  --robot.id=bimanual_follower \
  --robot.cameras="${cameras}" \
  --teleop.type=bi_so101_leader \
  --teleop.left_arm_port="${left_leader}" \
  --teleop.right_arm_port="${right_leader}" \
  --teleop.id=bimanual_leader \
  --display_data=true \
  --dataset.repo_id="${repo_id}" \
  --dataset.num_episodes="${num_episodes}" \
  --dataset.single_task="${single_task}" \
  ${push_flag} \
  ${episode_time_flag} \
  ${reset_time_flag} \
  ${resume_flag}
