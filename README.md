# lerobot-so101-bimanual

Bimanual Manipulation Support for LeRobot SO-101

## Installation

### Environment Setup

Create a virtual environment with Python 3.10, using conda:

```bash
conda create -y -n lerobot python=3.10
```

Then activate your conda environment, you have to do this each time you open a shell to use lerobot:

```bash
conda activate lerobot
```

When using `conda`, install `ffmpeg` in your environment:

```bash
conda install ffmpeg -c conda-forge
```

### Install Dependencies (LeRobot)

First, clone the repository and navigate into the directory:

```bash
git clone https://github.com/leehe228/lerobot-so101-bimanual.git
cd lerobot-so101-bimanual/library/lerobot
```

```bash
pip install -e .
pip install -e ".[feetech]"
```

## Robot Setup

### Configure the Motors

**1. Find the USB ports associated with each arm.** To find the port for each bus servo adapter, connect MotorBus to your computer via USB and power. Run the following script and disconnect the MotorBus when prompted:

```bash
lerobot-find-port
```

On Linux, you might need to give access to the USB ports by running:

```bash
sudo chmod 666 /dev/ttyACM0
sudo chmod 666 /dev/ttyACM1
```

Example output:

```bash
Finding all available ports for the MotorBus.
['/dev/ttyACM0', '/dev/ttyACM1']
Remove the usb cable from your MotorsBus and press Enter when done.

[...Disconnect corresponding leader or follower arm and press Enter...]

The port of this MotorsBus is /dev/ttyACM1
Reconnect the USB cable.
```

**2. Set the motors ids and baudrates.**

For follower arm:

```bash
lerobot-setup-motors \
    --robot.type=so101_follower \
    --robot.port=/dev/tty.usbmodem585A0076841
```

For leader arm:

```bash
lerobot-setup-motors \
    --teleop.type=so101_leader \
    --teleop.port=/dev/tty.usbmodem575E0031751
```

### Calibration for Bimanual Setup

First you need to move the robot to the position where all joints are in the middle of their ranges. Then after pressing enter you have to move each joint through its full range of motion.

For follower (left and right) arms:

```bash
lerobot-calibrate \
    --robot.type=bi_so101_follower \
    --robot.left_arm_port=/dev/tty.aaaa \ # <- The port of left follower arm robot
    --robot.right_arm_port=/dev/tty.bbbb \ # <- The port of right follower arm robot
    --robot.id=bimanual_follower # <- Give the robot a unique name
```

For leader (left and right) arms:

```bash
lerobot-calibrate \
    --teleop.type=bi_so101_leader \
    --teleop.left_arm_port=/dev/tty.xxxx \ # <- The port of left leader arm robot 
    --teleop.right_arm_port=/dev/tty.yyyy \ # <- The port of right leader arm robot 
    --teleop.id=bimanual_leader # <- Give the robot a unique name
```

### Teleoperation

```bash
lerobot-teleoperate \
    --robot.type=bi_so101_follower \
    --robot.left_arm_port=/dev/tty.aaaa \
    --robot.right_arm_port=/dev/tty.bbbb \
    --robot.id=bimanual_follower \
    --teleop.type=bi_so101_leader \
    --teleop.left_arm_port=/dev/tty.xxxx \
    --teleop.right_arm_port=/dev/tty.yyyy \
    --teleop.id=bimanual_leader
```

**Find Cameras.**

```bash
lerobot-find-cameras
```

**Teleoperation with cameras.**

```bash
lerobot-teleoperate \
  --robot.type=bi_so101_follower \
  --robot.left_arm_port=/dev/tty.aaaa \
  --robot.right_arm_port=/dev/tty.bbbb \
  --robot.id=bimanual_follower \
  --robot.cameras="{ 
    front: { 
      type: opencv, index_or_path: 0, 
      width: 1280, height: 720, fps: 30
    }, 
    wrist: {
      type: opencv, index_or_path: 1, 
      width: 1280, height: 720, fps: 30
    }, 
    wrist2: {
        type: opencv, index_or_path: 2, 
        width: 1280, height: 720, fps: 30}
  }" \
  --teleop.type=bi_so101_leader \
  --teleop.left_arm_port=/dev/tty.xxxx \
  --teleop.right_arm_port=/dev/tty.yyyy \
  --teleop.id=bimanual_leader \
  --display_data=true
```

### Record a Dataset

Add your token to the CLI by running this command:

```bash
huggingface-cli login --token ${HUGGINGFACE_TOKEN} --add-to-git-credential
```

Then store your Hugging Face repository name in a variable:

```bash
HF_USER=$(hf auth whoami | head -n 1)
echo $HF_USER
```

Now you can record a dataset. To record 5 episodes and upload your dataset to the hub, adapt the code below for your robot and execute the command or API example.

```bash
lerobot-record \
  --robot.type=bi_so101_follower \
  --robot.left_arm_port=/dev/tty.aaaa \
  --robot.right_arm_port=/dev/tty.bbbb \
  --robot.id=bimanual_follower \
  --robot.cameras="{ 
    front: { 
      type: opencv, index_or_path: 0, 
      width: 1280, height: 720, fps: 30
    }, 
    wrist: {
      type: opencv, index_or_path: 1, 
      width: 1280, height: 720, fps: 30
    }, 
    wrist2: {
        type: opencv, index_or_path: 2, 
        width: 1280, height: 720, fps: 30}
  }" \
  --teleop.type=bi_so101_leader \
  --teleop.left_arm_port=/dev/tty.xxxx \
  --teleop.right_arm_port=/dev/tty.yyyy \
  --teleop.id=bimanual_leader \
  --display_data=true \
  --dataset.repo_id=${HF_USER}/record-test \
  --dataset.num_episodes=5 \
  --dataset.single_task="Grab the black cube together"
```

**Dataset Upload.**

Locally, your dataset is stored in this folder: ~/.cache/huggingface/lerobot/{repo-id}. At the end of data recording, your dataset will be uploaded on your Hugging Face page (e.g. `https://huggingface.co/datasets/${HF_USER}/so101_test`) that you can obtain by running:

```bash
echo https://huggingface.co/datasets/${HF_USER}/so101_test
```

Your dataset will be automatically tagged with LeRobot for the community to find it easily, and you can also add custom tags (in this case tutorial for example).

You can look for other LeRobot datasets on the hub by searching for LeRobot tags.

You can also push your local dataset to the Hub manually, running:

```bash
huggingface-cli upload ${HF_USER}/record-test ~/.cache/huggingface/lerobot/{repo-id} --repo-type dataset
```

### Visualize a Dataset

If you uploaded your dataset to the hub with `--control.push_to_hub=true`, you can visualize your dataset online by copy pasting your repo id given by:

```bash
echo ${HF_USER}/so101_test
```
