# Running Isaac Sim Workloads on Omniverse Farm

[<img src="https://img.shields.io/badge/dockerhub-image-important.svg?logo=docker">](https://hub.docker.com/r/j3soon/omni-farm-isaac/tags)

## Installing Omniverse Farm

> Skip this section if you already have Omniverse Farm installed.

Follow the official [installation guide](https://docs.omniverse.nvidia.com/farm/latest/deployments/introduction.html) to install Omniverse Farm.

After installation, you should have a installed [Farm Queue](https://docs.omniverse.nvidia.com/farm/latest/queue.html), and one or more [Farm Agent](https://docs.omniverse.nvidia.com/farm/latest/agent.html) workers installed, which can be connected to the queue in subsequent steps. All Farm Agents should have access to the USD scenes that would be used in the submitted jobs through Nucleus.

Follow [this example](https://docs.omniverse.nvidia.com/farm/latest/farm_examples.html) to test your Omniverse Farm installation. First, [submit a rendering job](https://docs.omniverse.nvidia.com/farm/latest/farm_examples.html#send-a-render-to-the-queue) through [Movie Capture](https://docs.omniverse.nvidia.com/extensions/latest/ext_core/ext_movie-capture.html). Next, [connect a Farm Agent to the Farm Queue](https://docs.omniverse.nvidia.com/farm/latest/farm_examples.html#add-agents-to-execute-on-the-render-task), and make sure the job finished successfully by checking the output files. Please skip the [Blender decimation example](https://docs.omniverse.nvidia.com/farm/latest/farm_examples.html#custom-decimation-task) in the documentation, as it is not relevant to this repository.

> This repo is tested on Omniverse Farm 105.1.0 with [Kubernetes set up](https://docs.omniverse.nvidia.com/farm/latest/deployments/kubernetes.html). The scripts are tested within a environment consists of multiple OVX server nodes with L40 GPUs, a CPU-only head node, along with a large NVMe storage server. These servers are interconnected via a high-speed network utilizing the BlueField-3 DPU and ConnectX-7 NIC. See [this post](https://blogs.nvidia.com/blog/ovx-storage-partner-validation-program/) and [this post](https://nvidianews.nvidia.com/news/nvidia-launches-data-center-scale-omniverse-computing-system-for-industrial-digital-twins) for more information. However, the scripts in this repository should work on any Omniverse Farm setup, even on a single machine.

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

If a previous config is already installed, you must uninstall it before installing a new one. Otherwise, the scripts will create two VPN profiles with the same name, which can only be fixed by using the `openvpn3` command line tool directly. Specifically, use the following commands:

```sh
openvpn3 sessions-list
openvpn3 session-manage -D --session-path "/net/openvpn/v3/sessions/<SESSION_ID>"
openvpn3 configs-list --verbose
openvpn3 config-remove --path "/net/openvpn/v3/configuration/<CONFIG_ID>"
```

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

## Examples for Running More Complex Tasks

> Make sure to follow the **Running Isaac Sim Tasks** section before moving on to this section.

In this section, we only uses the [j3soon/omni-farm-isaac](https://hub.docker.com/r/j3soon/omni-farm-isaac/tags) docker image for simplicity. You can build your own docker image with the necessary dependencies and scripts for your tasks. This will require you to write a custom job definition and optionally copy `omnicli` when building your docker image.

(TODO: Add Isaac Lab Example)

## Running Isaac Sim Jobs Locally During Development

For headless tasks, simply follow [the official guide](https://docs.omniverse.nvidia.com/isaacsim/latest/installation/install_container.html).

If your task requires a GUI during development, see [this guide](https://github.com/j3soon/isaac-extended#docker-container-with-display).

## Developer Notes

- The job definitions used above contains minimal configuration. You can include more configuration options by referring to the [Job Definition Docs](https://docs.omniverse.nvidia.com/farm/latest/guides/creating_job_definitions.html) and the [Farm Examples](https://docs.omniverse.nvidia.com/farm/latest/farm_examples.html).
- The sample job definition files and the `scripts/save_job.sh` script only allows the use of a single argument `args`. You need to modify the job definition file and script to include more arguments if necessary.
- Saving an updated job definition (`scripts/save_job.sh`) and submitting a task that refers to that job definition (`scripts/submit_task.sh`) doesn't seem to be always in sync. Please submit some dummy tasks to verify that the job definition changes are reflected in new tasks before submitting the actual task.
- The default time limit (`active_deadline_seconds`) for K8s pods are set to `86400` (1 day) by Omniverse Farm. If the task takes longer than 1 day, the task will be terminated. After the K8s pod has been terminated, the K8s job will restart it once (`backoffLimit: 1`) even though `is_retryable` is set to False. This restarted K8s pod cannot be cancelled through the Omniverse UI. You can modify the time limit by changing the `active_deadline_seconds` field in the job definition file, we set it to 10 days in all job definitions, which is enough for most tasks.
- The behavior of K8s jobs restarting K8s pods (`backoffLimit: 1`) after K8s pod termination appear to happen when the command exits with a non-zero status code. I believe this could be fixed by overriding the K8s job template during Omniverse Farm installation, as described [here](https://docs.omniverse.nvidia.com/farm/latest/deployments/kubernetes.html#step-2). However, I haven't tested this yet.
- In the examples, the number of requested GPUs per task is set to 1. You can modify the number of GPUs for different tasks by changing the `nvidia.com/gpu` field in the job definition file.
- The `job_spec_path` is required for options such as `args` and `env` to be saved. If the `job_spec_path` is `null`, these options will be forced empty. In our examples, we simply set it to a dummy value (`"null"`). See [this thread](https://nvidia.slack.com/archives/C03AZDA710T/p1689869120574269) for more details.
- If relative paths are not setup correctly, the task might fail due to the behavior of automatically prepending the path with the current working directory (`/isaac-sim`). This behavior may result in errors such as:
  ```
  /isaac-sim/kit/python/bin/python3: can't open file '/isaac-sim/ ': [Errno 2] No such file or directory`.
  ```
- If a task refers to a job definition that doesn't exist, the task will be stuck in the `submitted` state.
- If a task refers to a docker image or a PVC that doesn't exist, the task will be stuck in the `running` state.
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

## References

- [Omniverse Farm Documentation](https://docs.omniverse.nvidia.com/farm/latest/index.html)
