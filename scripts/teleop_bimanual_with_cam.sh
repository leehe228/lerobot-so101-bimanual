#!/usr/bin/env bash
set -euo pipefail

PORT_FILE="scripts/port.yaml"
CAMERA_FILE="scripts/camera.yaml"

if [[ ! -f "$PORT_FILE" ]]; then
  echo "Missing $PORT_FILE" >&2
  exit 1
fi

if [[ ! -f "$CAMERA_FILE" ]]; then
  echo "Missing $CAMERA_FILE" >&2
  exit 1
fi

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

cameras="{ front: { type: ${front_type}, index_or_path: ${front_index}, width: ${front_width}, height: ${front_height}, fps: ${front_fps} }, left_wrist: { type: ${wrist_type}, index_or_path: ${wrist_index}, width: ${wrist_width}, height: ${wrist_height}, fps: ${wrist_fps} }, right_wrist: { type: ${wrist2_type}, index_or_path: ${wrist2_index}, width: ${wrist2_width}, height: ${wrist2_height}, fps: ${wrist2_fps} } }"

lerobot-teleoperate \
  --robot.type=bi_so101_follower \
  --robot.left_arm_port="${left_follower}" \
  --robot.right_arm_port="${right_follower}" \
  --robot.id=bimanual_follower \
  --robot.cameras="${cameras}" \
  --teleop.type=bi_so101_leader \
  --teleop.left_arm_port="${left_leader}" \
  --teleop.right_arm_port="${right_leader}" \
  --teleop.id=bimanual_leader \
  --display_data=true
