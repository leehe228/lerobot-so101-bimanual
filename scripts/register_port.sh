#!/usr/bin/env bash
set -euo pipefail

find_port() {
  local label="$1"
  local output_file
  local port

  echo "$label"
  output_file="$(mktemp)"
  # Run under a pseudo-tty so Python doesn't fully buffer stdout.
  # Keep stdin attached to terminal so lerobot-find-port can read input().
  script -q /dev/null lerobot-find-port < /dev/tty | tee "$output_file"

  port=$(
    cat "$output_file" \
      | sed -n "s/.*The port of this MotorsBus is ['\"]\\([^'\"]*\\)['\"].*/\\1/p" \
      | tail -n 1
  )

  rm -f "$output_file"

  if [[ -z "${port}" ]]; then
    echo "Failed to parse port from lerobot-find-port output." >&2
    exit 1
  fi

  printf "%s\n" "$port"
}

left_follower_port=$(find_port "[1/4] Left follower arm")
left_leader_port=$(find_port "[2/4] Left leader arm")
right_follower_port=$(find_port "[3/4] Right follower arm")
right_leader_port=$(find_port "[4/4] Right leader arm")

cat <<EOF > port.yaml
left_follower: ${left_follower_port}
left_leader: ${left_leader_port}
right_follower: ${right_follower_port}
right_leader: ${right_leader_port}
EOF

echo "Saved ports to port.yaml"
