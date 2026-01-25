# Bimanual SO-101 Scripts & Configs

This document explains the configuration files and helper scripts used to calibrate, teleoperate, record, and replay a bimanual SO-101 setup.

All files live under `scripts/`:

- Configs: `scripts/port.yaml`, `scripts/camera.yaml`, `scripts/dataset_config.yaml`
- Scripts: `scripts/register_port.sh`, `scripts/calibrate_bimanual.sh`, `scripts/teleop_bimanual_with_cam.sh`, `scripts/record_bimanual.sh`, `scripts/replay_bimanual.sh`

> Note on working directory
>
> - `register_port.sh` and `calibrate_bimanual.sh` read/write `port.yaml` **in the current working directory**.
> - `teleop_bimanual_with_cam.sh`, `record_bimanual.sh`, and `replay_bimanual.sh` always read **`scripts/port.yaml`** (and other config files under `scripts/`).
>
> Recommended flow:
> 1) Run `register_port.sh` and `calibrate_bimanual.sh` **from inside `scripts/`** so `scripts/port.yaml` is created and used.
> 2) Run the other scripts from the repository root.

---

## Configuration Files

### `scripts/port.yaml`
USB serial ports for the four arms:

```yaml
left_follower: /dev/tty.usbmodemXXXX
left_leader: /dev/tty.usbmodemYYYY
right_follower: /dev/tty.usbmodemZZZZ
right_leader: /dev/tty.usbmodemWWWW
```

Used by:
- `calibrate_bimanual.sh`
- `teleop_bimanual_with_cam.sh`
- `record_bimanual.sh`
- `replay_bimanual.sh` (follower arms only)

### `scripts/camera.yaml`
Camera configuration for teleoperation and recording:

```yaml
front:
  type: opencv
  index_or_path: 1
  width: 1280
  height: 720
  fps: 30
wrist: # left
  type: opencv
  index_or_path: 0
  width: 1280
  height: 720
  fps: 30
wrist2: # right
  type: opencv
  index_or_path: 2
  width: 1280
  height: 720
  fps: 30
```

Script mapping:
- `front` → `front`
- `wrist` → `left_wrist`
- `wrist2` → `right_wrist`

Used by:
- `teleop_bimanual_with_cam.sh`
- `record_bimanual.sh`

### `scripts/dataset_config.yaml`
Dataset settings used by recording and replay:

```yaml
num_eposides: 1
single_task: Grab the red nipper together
hf_user: leehe228
repo: record-test
push_to_hub: False
episode_time_s: 10
reset_time_s: 10
```

Fields:
- `num_eposides` (typo intentional): number of episodes to record.
- `single_task`: task description saved in the dataset.
- `hf_user`: Hugging Face username or org.
- `repo`: dataset repo name (combined with `hf_user`).
- `push_to_hub`: `True` / `False` → passed to `--dataset.push_to_hub`.
- `episode_time_s`: recording time per episode.
- `reset_time_s`: reset time between episodes.

Used by:
- `record_bimanual.sh`
- `replay_bimanual.sh` (for `hf_user` and `repo` only)

---

## Scripts

### `scripts/register_port.sh`
Finds the USB port for each arm using `lerobot-find-port` and writes `port.yaml` in the **current directory**.

Usage (recommended):
```bash
cd scripts
./register_port.sh
```

What it does:
- Prompts you to disconnect/reconnect each arm’s USB adapter in order:
  1) left follower
  2) left leader
  3) right follower
  4) right leader
- Parses `lerobot-find-port` output and saves a new `port.yaml`.

### `scripts/calibrate_bimanual.sh`
Runs calibration for follower and leader arms using ports from `port.yaml` in the **current directory**.

Usage (recommended):
```bash
cd scripts
./calibrate_bimanual.sh
```

### `scripts/teleop_bimanual_with_cam.sh`
Teleoperation with cameras. Reads:
- `scripts/port.yaml`
- `scripts/camera.yaml`

Usage (from repo root):
```bash
./scripts/teleop_bimanual_with_cam.sh
```

### `scripts/record_bimanual.sh`
Records a dataset with cameras. Reads:
- `scripts/port.yaml`
- `scripts/camera.yaml`
- `scripts/dataset_config.yaml`

Usage (from repo root):
```bash
./scripts/record_bimanual.sh
```

Options:
- `--resume` : continue an existing dataset.
  - Errors if the dataset cache directory does **not** exist.
- `--reset` : delete existing dataset cache and start from scratch.
  - If the dataset exists, it will be removed.
- No option: start fresh **only if** the dataset directory does not exist. Otherwise it errors.

Dataset cache path rule:
```
${HF_HOME:-$HOME/.cache/huggingface}/lerobot/{repo_id}
```
Where `{repo_id}` is `hf_user/repo` from `dataset_config.yaml`.

### `scripts/replay_bimanual.sh`
Replays a recorded episode on the **follower** robot.
Reads:
- `scripts/port.yaml` (follower ports)
- `scripts/dataset_config.yaml` (hf_user + repo)

Usage (from repo root):
```bash
./scripts/replay_bimanual.sh --episode 0
```

Required option:
- `--episode <index>` : episode index to replay.

---

## Quick Start (Recommended Order)

1) Find ports (writes `scripts/port.yaml`):
```bash
cd scripts
./register_port.sh
```

2) Calibrate both arms (reads `scripts/port.yaml`):
```bash
cd scripts
./calibrate_bimanual.sh
```

3) Teleoperate with cameras:
```bash
cd ..
./scripts/teleop_bimanual_with_cam.sh
```

4) Record dataset:
```bash
./scripts/record_bimanual.sh
```

5) Replay episode:
```bash
./scripts/replay_bimanual.sh --episode 0
```
