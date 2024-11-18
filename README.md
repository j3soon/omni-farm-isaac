# Running Isaac Sim Workloads on Omniverse Farm

These scripts are only tested on Linux environment (Ubuntu). If you are using MacOS or Windows, consider using Virtual Box to setup a Ubuntu virtual machine. WSL2 may work but hasn't been tested.

## Support Matrix

The scripts below are currently based on Isaac Sim 4.1.0 and Isaac Lab 1.1.0. The scripts should work on other versions of Isaac Sim and Isaac Lab, but you may need to modify the scripts accordingly.

### Isaac Sim

| Docker Image | Isaac Sim | Ubuntu |
|--------------|-----------|--------|
| [`j3soon/omni-farm-isaac-sim:4.2.0`](https://hub.docker.com/r/j3soon/omni-farm-isaac-sim/tags?name=4.2.0) | 4.2.0 | 22.04.3 LTS |
| [`j3soon/omni-farm-isaac-sim:4.1.0`](https://hub.docker.com/r/j3soon/omni-farm-isaac-sim/tags?name=4.1.0) | 4.1.0 | 22.04.3 LTS |
| [`j3soon/omni-farm-isaac-sim:4.0.0`](https://hub.docker.com/r/j3soon/omni-farm-isaac-sim/tags?name=4.0.0) | 4.0.0 | 22.04.3 LTS |
| [`j3soon/omni-farm-isaac-sim:2023.1.1`](https://hub.docker.com/r/j3soon/omni-farm-isaac-sim/tags?name=2023.1.1) | 2023.1.1 | 22.04.3 LTS |

### Isaac Lab

| Docker Image | Isaac Lab | Isaac Sim | Ubuntu |
|--------------|-----------|-----------|--------|
| [`j3soon/omni-farm-isaac-lab:1.1.0`](https://hub.docker.com/r/j3soon/omni-farm-isaac-lab/tags?name=1.1.0) | 1.1.0 | 4.1.0 | 22.04.3 LTS |

## Installing Omniverse Farm

> Only the cluster admin should read this section. Please skip to the [Setup section](#setup) if you are a user or already have Omniverse Farm installed.

### Pre-Installation

Before proceeding with the installation, make sure you have modified the following values:

- `max_capacity: 32`  
  The default maximum capacity of the Omniverse Farm [is set to 32](https://docs.omniverse.nvidia.com/farm/latest/deployments/kubernetes.html#b-capacity-tuning). You can modify this value to a number larger than the GPUs available in your system. This can be found in the `values.yaml` file in the `omniverse-farm-x.x.x.tgz` file:
  ```yaml
  capacity:
    # -- Specify the max number of jobs the controller is allowed to run.
    max_capacity: 32
  ```
  and modify it to something like:
  ```yaml
  capacity:
    # -- Specify the max number of jobs the controller is allowed to run.
    max_capacity: 1024
  ```

(Note that the pre-installation steps are not tested on a real machine yet...)

### Installation

Follow the official [installation guide](https://docs.omniverse.nvidia.com/farm/latest/deployments/introduction.html) to install Omniverse Farm.

After installation, you should have a installed [Farm Queue](https://docs.omniverse.nvidia.com/farm/latest/queue.html), and one or more [Farm Agent](https://docs.omniverse.nvidia.com/farm/latest/agent.html) workers installed, which can be connected to the queue in subsequent steps. All Farm Agents should have access to the USD scenes that would be used in the submitted jobs through Nucleus.

Follow [this example](https://docs.omniverse.nvidia.com/farm/latest/farm_examples.html) to test your Omniverse Farm installation. First, [submit a rendering job](https://docs.omniverse.nvidia.com/farm/latest/farm_examples.html#send-a-render-to-the-queue) through [Movie Capture](https://docs.omniverse.nvidia.com/extensions/latest/ext_core/ext_movie-capture.html). Next, [connect a Farm Agent to the Farm Queue](https://docs.omniverse.nvidia.com/farm/latest/farm_examples.html#add-agents-to-execute-on-the-render-task), and make sure the job finished successfully by checking the output files. Please skip the [Blender decimation example](https://docs.omniverse.nvidia.com/farm/latest/farm_examples.html#custom-decimation-task) in the documentation, as it is not relevant to this repository.

> This repo is tested on Omniverse Farm 105.1.0 with [Kubernetes set up](https://docs.omniverse.nvidia.com/farm/latest/deployments/kubernetes.html). The scripts are tested within a environment consists of multiple OVX server nodes with L40 GPUs, a CPU-only head node, along with a large NVMe storage server. These servers are interconnected via a high-speed network utilizing the BlueField-3 DPU and ConnectX-7 NIC. See [this post](https://blogs.nvidia.com/blog/ovx-storage-partner-validation-program/) and [this post](https://nvidianews.nvidia.com/news/nvidia-launches-data-center-scale-omniverse-computing-system-for-industrial-digital-twins) for more information. However, the scripts in this repository should work on any Omniverse Farm setup, even on a single machine.

### Post-Installation

If you forgot to perform the pre-installation steps, you can still perform them after installation:

- `max_capacity: 32`  
  ```sh
  kubectl edit cm/controller-capacity -n ov-farm
  ```
  Change
  ```yaml
  apiVersion: v1
  data:
    capacity.json: |2-

      {
        "max_capacity": 32
      }
  kind: ConfigMap
  ```
  to
  ```yaml
  apiVersion: v1
  data:
    capacity.json: |2-

      {
        "max_capacity": 512
      }
  kind: ConfigMap
  ```
  save and close the file. Then run:
  ```sh
  kubectl delete pods/controller-0 -n ov-farm
  ```
  and wait for the controller pod to automatically restart.

## Setup

Clone this repository:

```sh
git clone https://github.com/j3soon/omni-farm-isaac.git
cd omni-farm-isaac
```

Install `jq` for JSON parsing. For example if you are using Ubuntu:

```sh
sudo apt-get update
sudo apt-get install -y jq
```

Fill in the Omniverse Farm server information in `secrets/env.sh`, for example:

```
export FARM_API_KEY="s3cr3t"
export FARM_URL="http://localhost:8222"
export FARM_USER="j3soon"
export NUCLEUS_HOSTNAME="localhost"
```

Then, for each shell session, make sure to source the environment variables by running the following command in the root directory of this repository:

```sh
source secrets/env.sh
```

In some examples below, we will upload files to Nucleus through [`omnicli`](https://docs.omniverse.nvidia.com/connect/latest/connect-sample.html#omni-cli), you can use the GUI to upload files to Nucleus instead.

All following commands assume you are in the root directory of this repository (`omni-farm-isaac`) and have sourced the environment variables file (`secrets/env.sh`).

## Setup VPN

> Skip this section if accessing your Omniverse Farm doesn't require a VPN.

There doesn't seem to be a way to use the OpenVPN Connect v3 GUI on Linux as in [Windows](https://openvpn.net/client/client-connect-vpn-for-windows/) or [MacOS](https://openvpn.net/client-connect-vpn-for-mac-os/). Instead, use the command line to install OpenVPN 3 Client by following [the official guide](https://openvpn.net/cloud-docs/owner/connectors/connector-user-guides/openvpn-3-client-for-linux.html).

Then, copy your `.ovpn` client config file to `secrets/client.ovpn` and install the config, and connect to the VPN with:

```sh
scripts/vpn/install_config.sh client.ovpn
scripts/vpn/connect.sh
```

To disconnect from the VPN, and uninstall the VPN config, run:

```sh
scripts/vpn/disconnect.sh
scripts/vpn/uninstall_config.sh
```

These 4 scripts are just wrappers for the `openvpn3` command line tool. See the [official documentation](https://community.openvpn.net/openvpn/wiki/OpenVPN3Linux) for more details.

> If a previous config is already installed, you must uninstall it before installing a new one. Otherwise, the scripts will create two VPN profiles with the same name, which can only be fixed by using the `openvpn3` command line tool directly. Specifically, use the following commands:
>
> ```sh
> openvpn3 sessions-list
> openvpn3 session-manage -D --session-path "/net/openvpn/v3/sessions/<SESSION_ID>"
> openvpn3 configs-list --verbose
> openvpn3 config-remove --path "/net/openvpn/v3/configuration/<CONFIG_ID>"
> ```

## Running Shell Commands

Save the job definition file and verify it:

```sh
scripts/save_job.sh echo-example
scripts/load_job.sh
```

Then, submit the job:

```sh
scripts/submit_task.sh echo-example "hello world" "Echo hello world"
```

You can remove the job definition file after the job has finished:

```sh
scripts/remove_job.sh echo-example
```

This demo allows running arbitrary shell commands on Omniverse Farm.

## Running Isaac Sim Tasks

### Built-in Tasks

Save the job definition file and verify it:

```sh
scripts/save_job.sh isaac-sim-dummy-example
scripts/load_job.sh
```

Then, submit the job:

```sh
scripts/submit_task.sh isaac-sim-dummy-example "./standalone_examples/api/omni.isaac.core/time_stepping.py" "Isaac Sim Time Stepping"
# or
scripts/submit_task.sh isaac-sim-dummy-example "./standalone_examples/api/omni.isaac.core/simulation_callbacks.py" "Isaac Sim Simulation Callbacks"
```

You can remove the job definition file after the job has finished:

```sh
scripts/remove_job.sh isaac-sim-dummy-example
```

This demo allows running arbitrary built-in Isaac Sim scripts on Omniverse Farm.

### Custom Tasks

This script assumes that the Nucleus server has username `admin` and password `admin`. The commands below will fail if the Nucleus server has a different username and password. In this case, refer to the next section on how to setup Nucleus credentials.

Use [`omnicli`](https://docs.omniverse.nvidia.com/connect/latest/connect-sample.html#omni-cli) to upload the script to Nucleus:

```sh
cd thirdparty/omnicli
./omnicli copy "../../tasks/isaac-sim-simulation-example.py" "omniverse://$NUCLEUS_HOSTNAME/Projects/J3soon/Isaac/4.1/Scripts/isaac-sim-simulation-example.py"
cd ../..
```

Save the job definition file and verify it:

```sh
scripts/save_job.sh isaac-sim-basic-example
scripts/load_job.sh
```

Then, submit the job:

```sh
scripts/submit_task.sh isaac-sim-basic-example \
"/run.sh \
  --download-src 'omniverse://$NUCLEUS_HOSTNAME/Projects/J3soon/Isaac/4.1/Scripts/isaac-sim-simulation-example.py' \
  --download-dest '/src/isaac-sim-simulation-example.py' \
  --upload-src '/results/isaac-sim-simulation-example.txt' \
  --upload-dest 'omniverse://$NUCLEUS_HOSTNAME/Projects/J3soon/Isaac/4.1/Results/isaac-sim-simulation-example.txt' \
  './python.sh -u /src/isaac-sim-simulation-example.py 10'" \
  "Isaac Sim Cube Fall"
```

You can remove the job definition file after the job has finished:

```sh
scripts/remove_job.sh isaac-sim-basic-example
```

This demo allows running arbitrary Isaac Sim scripts on Omniverse Farm by downloading the necessary files, executing the specified command, and then uploading the output files to Nucleus.

### Setting Nucleus Credentials

If your Nucleus server have a non-default username and password. Use `./omnicli auth [username] [password]` to enter your credentials for uploading files. Alternatively, you can use Omniverse Launcher to perform authentication through a GUI. In addition, use the `isaac-sim-nucleus-example.json` job description instead to include your username and password. The job description assumes `nucleus-secret` has been added to the K8s secrets by the admin, including `OMNI_USER` and `OMNI_PASS`. Alternatively, if security is not a concern, you may include the username and password directly through the `env` entry in the job descriptions.

Use [`omnicli`](https://docs.omniverse.nvidia.com/connect/latest/connect-sample.html#omni-cli) to upload the script to Nucleus:

```sh
cd thirdparty/omnicli
./omnicli copy "../../tasks/isaac-sim-simulation-example.py" "omniverse://$NUCLEUS_HOSTNAME/Projects/J3soon/Isaac/4.1/Scripts/isaac-sim-simulation-example.py"
cd ../..
```

Save the job definition file and verify it:

```sh
scripts/save_job.sh isaac-sim-nucleus-example
scripts/load_job.sh
```

Then, submit the job:

```sh
scripts/submit_task.sh isaac-sim-nucleus-example \
"/run.sh \
  --download-src 'omniverse://$NUCLEUS_HOSTNAME/Projects/J3soon/Isaac/4.1/Scripts/isaac-sim-simulation-example.py' \
  --download-dest '/src/isaac-sim-simulation-example.py' \
  --upload-src '/results/isaac-sim-simulation-example.txt' \
  --upload-dest 'omniverse://$NUCLEUS_HOSTNAME/Projects/J3soon/Isaac/4.1/Results/isaac-sim-simulation-example.txt' \
  './python.sh -u /src/isaac-sim-simulation-example.py 10'" \
  "Isaac Sim Cube Fall"
```

You can remove the job definition file after the job has finished:

```sh
scripts/remove_job.sh isaac-sim-nucleus-example
```

### Setting Persistent Volumes

The aforementioned methods only upload the results after the specified command runs successfully, potentially resulting in loss of results if the command fails. To prevent this, you can mount a persistent volume to the container. The `isaac-sim-volume-example.json` job description assumes that `nfs-pv` connecting to a storage server through NFS has been added to K8s persistent volume (PV), along with a corresponding `nfs-pvc` persistent volume claim (PVC) by the admin. This method allows you to keep the partial results even if the command fails.

> This NFS setup is preferable for multiple nodes over using [`volumeMounts.mountPath`](https://kubernetes.io/docs/concepts/storage/volumes/#hostpath-configuration-example). The latter mounts the volume to the node where the pod is running, which can become challenging to manage in clusters with multiple nodes.

Use [`omnicli`](https://docs.omniverse.nvidia.com/connect/latest/connect-sample.html#omni-cli) to upload the script to Nucleus:

```sh
cd thirdparty/omnicli
./omnicli copy "../../tasks/isaac-sim-simulation-example.py" "omniverse://$NUCLEUS_HOSTNAME/Projects/J3soon/Isaac/4.1/Scripts/isaac-sim-simulation-example.py"
cd ../..
```

Save the job definition file and verify it:

```sh
scripts/save_job.sh isaac-sim-volume-example
scripts/load_job.sh
```

Then, submit the job:

```sh
scripts/submit_task.sh isaac-sim-volume-example \
"/run.sh \
  --download-src 'omniverse://$NUCLEUS_HOSTNAME/Projects/J3soon/Isaac/4.1/Scripts/isaac-sim-simulation-example.py' \
  --download-dest '/src/isaac-sim-simulation-example.py' \
  'ls /mnt/nfs' \
  'mkdir -p /mnt/nfs/results' \
  './python.sh -u /src/isaac-sim-simulation-example.py 10' \
  'cp /results/isaac-sim-simulation-example.txt /mnt/nfs/results/isaac-sim-simulation-example.txt'" \
  "Isaac Sim Cube Fall"
```

You can remove the job definition file after the job has finished:

```sh
scripts/remove_job.sh isaac-sim-volume-example
```

Note that you can remove the `--download-src` and `--download-dest` options if the script is stored in the persistent volume. In addition, the `cp` command here is only for demonstration purposes, the best practice is to directly write the results in the persistent volume. This can be achieved by making the script accept an additional argument for the output directory.

> If your job stuck in the `running` state and output no logs, you may have mounted an incorrect PVC. Double check the `README` file and example job description provided by the cluster admin.

> If you are not running Isaac tasks, you can skip the remaining sections.

## Running Isaac Lab Tasks

> Make sure to follow the **Running Isaac Sim Tasks** section before moving on to this section.

The demo tasks here assume the aforementioned `nuclues-secret` and `nfs-pvc` setup. You can modify the job definition files to include your own credentials and persistent volume claim.

In this section, we only uses the [j3soon/omni-farm-isaaclab](https://hub.docker.com/r/j3soon/omni-farm-isaaclab/tags) docker image for simplicity. You can build your own docker image with the necessary dependencies and scripts for your tasks. This will require you to write a custom job definition and optionally copy `omnicli` when building your docker image.

### Built-in Tasks

Save the job definition file and verify it:

```sh
scripts/save_job.sh isaac-lab-volume-example
scripts/load_job.sh
```

Then, submit the job:

```sh
scripts/submit_task.sh isaac-lab-volume-example \
"/run.sh \
  --upload-src '/root/IsaacLab/logs' \
  --upload-dest 'omniverse://$NUCLEUS_HOSTNAME/Projects/J3soon/Isaac/4.1/Results/IsaacLab/logs' \
  'ls /mnt/nfs' \
  'mkdir -p /mnt/nfs/results/IsaacLab/logs' \
  'ln -s /mnt/nfs/results/IsaacLab/logs logs' \
  '. /opt/conda/etc/profile.d/conda.sh' \
  'conda activate isaaclab' \
  './isaaclab.sh -p source/standalone/workflows/rl_games/train.py --task Isaac-Ant-v0 --headless'" \
  "Isaac Lab RL-Games Isaac-Ant-v0"
```

You can remove the job definition file after the job has finished:

```sh
scripts/remove_job.sh isaac-lab-volume-example
```

This demo allows running arbitrary built-in Isaac Lab scripts on Omniverse Farm.

## Running Isaac Sim Jobs Locally During Development

For headless tasks, simply follow [the official guide](https://docs.omniverse.nvidia.com/isaacsim/latest/installation/install_container.html).

If your task requires a GUI during development, see [this guide](https://github.com/j3soon/isaac-extended#docker-container-with-display).

Refer to [scripts/docker](scripts/docker) for potential useful scripts for running Isaac Sim tasks locally.

## Developer Notes

- The job definitions used above contains minimal configuration. You can include more configuration options by referring to the [Job Definition Docs](https://docs.omniverse.nvidia.com/farm/latest/guides/creating_job_definitions.html) and the [Farm Examples](https://docs.omniverse.nvidia.com/farm/latest/farm_examples.html).
- The sample job definition files and the `scripts/save_job.sh` script only allows the use of a single argument `args`. You need to modify the job definition file and script to include more arguments if necessary.
- Saving an updated job definition (`scripts/save_job.sh`) and submitting a task that refers to that job definition (`scripts/submit_task.sh`) doesn't seem to be always in sync. Please submit some dummy tasks to verify that the job definition changes are reflected in new tasks before submitting the actual task.
- The default time limit (`active_deadline_seconds`) for K8s pods are set to `86400` (1 day) by Omniverse Farm. If the task takes longer than 1 day, the task will be terminated. After the K8s pod has been terminated, the K8s job will restart it once (`backoffLimit: 1`) even though `is_retryable` is set to False. This restarted K8s pod cannot be cancelled through the Omniverse UI. You can modify the time limit by changing the `active_deadline_seconds` field in the job definition file, we set it to 10 days in all job definitions, which is enough for most tasks.
- The behavior of K8s jobs restarting K8s pods (`backoffLimit: 1`) after K8s pod termination appear to happen when the command exits with a non-zero status code. This issue can be observed by running the following:
  ```sh
  kubectl get jobs -n ov-farm -o yaml | grep backoffLimit
  ```
  - The default backoff limit of the Omniverse Farm is set to 1. Originally, I thought this could be fixed by overriding the K8s job template during Omniverse Farm pre-installation, as described [here](https://docs.omniverse.nvidia.com/farm/latest/deployments/kubernetes.html#step-2). However, after some trial and error with [@timost1234](https://github.com/timost1234), it seems that we cannot change this value. Since the `cm/controller-job-template-spec-overrides` ConfigMap doesn't seem to allow changing the `backoffLimit` field.
- In the examples, the number of requested GPUs per task is set to 1. You can modify the number of GPUs for different tasks by changing the `nvidia.com/gpu` field in the job definition file.
- The `job_spec_path` is required for options such as `args` and `env` to be saved. If the `job_spec_path` is `null`, these options will be forced empty. In our examples, we simply set it to a dummy value (`"null"`). See [this thread](https://nvidia.slack.com/archives/C03AZDA710T/p1689869120574269) for more details.
- If relative paths are not setup correctly, the task might fail due to the behavior of automatically prepending the path with the current working directory (`/isaac-sim`). This behavior may result in errors such as:
  ```
  /isaac-sim/kit/python/bin/python3: can't open file '/isaac-sim/ ': [Errno 2] No such file or directory`.
  ```
- If a task refers to a job definition that doesn't exist, the task will be stuck in the `submitted` state.
- If a task refers to a docker image or a PVC that doesn't exist, the task will be stuck in the `running` state.
  ```sh
  No logs found for task xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx on agent None: 'No logs found for Task xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx.'
  ```
- When using `tar` on a mounted volume, make sure to use the `--no-same-owner` flag to prevent the following error:
  ```
  tar: XXX: Cannot change ownership to uid XXX, gid XXX: Operation not permitted
  ```
- When using Omniverse Isaac Gym Envs with SKRL and Ray Tune, the task will sometimes complete but stuck in the `running` state.
- When using `omnicli`, sometimes the following error occurs:
  ```
  Error: no DISPLAY environment variable specified
  ```
  which can be fixed by running the `omnicli` command in a terminal with desktop support, and enter username and password through the browser.
- If the following error occurs in the Omniverse Farm UI:
  ```
  Error: Connection
  ```
  This may be due to incorrect Nuclues credentials or incorrect Nucleus server URL. Try launching a `sleep infinity` task and exec into the pod to debug the issue:
  ```sh
  kubectl exec -it -n ov-farm <POD_ID> -- /bin/bash
  # in the container
  env | grep OMNI
  # check that `OMNI_USER` and `OMNI_PASS` are set correctly
  apt-get update && apt-get install -y iputils-ping
  ping <NUCLEUS_HOSTNAME>
  # check that the Nucleus server is reachable
  ```
- Omniverse Farm webpage logs show the following error when using custom built docker image:
  ```sh

  #### Agent ID: controller-0.controller.ov-farm.svc.cluster.local-1
  /bin/bash: - : invalid option
  Process exited with return code: -1
  ```

  This may be due to building on Windows, try a Linux environment instead.

## References

- [Omniverse Farm Documentation](https://docs.omniverse.nvidia.com/farm/latest/index.html)
