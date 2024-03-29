# Running Isaac Sim Workloads on Omniverse Farm

[<img src="https://img.shields.io/badge/dockerhub-image-important.svg?logo=docker">](https://hub.docker.com/r/j3soon/omni-farm-isaac/tags)

## Installing Omniverse Farm

> Skip this section if you already have Omniverse Farm installed.

Follow the official [installation guide](https://docs.omniverse.nvidia.com/farm/latest/deployments/introduction.html) to install Omniverse Farm.

After installation, you should have a installed [Farm Queue](https://docs.omniverse.nvidia.com/farm/latest/queue.html), and one or more [Farm Agent](https://docs.omniverse.nvidia.com/farm/latest/agent.html) workers installed, which can be connected to the queue in subsequent steps. All Farm Agents should have access to the USD scenes that would be used in the submitted jobs through Nucleus.

Follow [this example](https://docs.omniverse.nvidia.com/farm/latest/farm_examples.html) to test your Omniverse Farm installation. First, [submit a rendering job](https://docs.omniverse.nvidia.com/farm/latest/farm_examples.html#send-a-render-to-the-queue) through [Movie Capture](https://docs.omniverse.nvidia.com/extensions/latest/ext_core/ext_movie-capture.html). Next, [connect a Farm Agent to the Farm Queue](https://docs.omniverse.nvidia.com/farm/latest/farm_examples.html#add-agents-to-execute-on-the-render-task), and make sure the job finished successfully by checking the output files. Please skip the [Blender decimation example](https://docs.omniverse.nvidia.com/farm/latest/farm_examples.html#custom-decimation-task) in the documentation, as it is not relevant to this repository.

> This repo is tested on Omniverse Farm 105.1.0 with [Kubernetes set up](https://docs.omniverse.nvidia.com/farm/latest/deployments/kubernetes.html).

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

## Setup VPN

> Skip this section if accessing your Omniverse Farm doesn't require a VPN.

There doesn't seem to be a way to use the OpenVPN Connect v3 GUI on Linux as in [Windows](https://openvpn.net/client/client-connect-vpn-for-windows/) or [MacOS](https://openvpn.net/client-connect-vpn-for-mac-os/). Instead, use the command line to install OpenVPN 3 Client by following [the official guide](https://openvpn.net/cloud-docs/owner/connectors/connector-user-guides/openvpn-3-client-for-linux.html).

Then, copy your `.ovpn` client config file to `secrets/client.ovpn` and install the config with:

```sh
scripts/vpn/install_config.sh client.ovpn
```

Finally, connect to the VPN with:

```sh
scripts/vpn/connect.sh
```

To disconnect from the VPN, run:

```sh
scripts/vpn/disconnect.sh
```

To uninstall the VPN config, run:

```sh
scripts/vpn/uninstall_config.sh
```

These 4 scripts are just wrappers for the `openvpn3` command line tool. See the [official documentation](https://community.openvpn.net/openvpn/wiki/OpenVPN3Linux) for more details.

## Running Shell Commands

All following commands assume you are in the root directory of this repository (`omni-farm-isaac`) and have sourced the environment variables file (`secrets/env.sh`). If a VPN connection is required, we also assume that you are connected to the VPN.

Save the job definition file and verify it:

```sh
source secrets/env.sh
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

## Running Built-in Isaac Sim Scripts

Save the job definition file and verify it:

```sh
source secrets/env.sh
scripts/save_job.sh isaac-sim-example
scripts/load_job.sh
```

Then, submit the job:

```sh
scripts/submit_task.sh isaac-sim-example "./standalone_examples/api/omni.isaac.core/time_stepping.py" "Isaac Sim Time Stepping"
# or
scripts/submit_task.sh isaac-sim-example "./standalone_examples/api/omni.isaac.core/simulation_callbacks.py" "Isaac Sim Simulation Callbacks"
```

You can remove the job definition file after the job has finished:

```sh
scripts/remove_job.sh isaac-sim-example
```

This demo allows running arbitrary built-in Isaac Sim scripts on Omniverse Farm.

To run custom Isaac Sim scripts, you may modify the job definition file to mount volumes into the container. Make sure to upload the custom scripts to the mounted volume before submitting tasks.

## Running Custom Isaac Sim Scripts

> The commands assume that the Nucleus server has username `admin` and password `admin`. If the Nucleus server has a different username and password, you may want to consider modifying `job_definitions/isaac-sim-output-example.json` to include the correct username and password. Specifically, by modifying the `capacity_requirements` entry:
> ```json
> ...
> "capacity_requirements": {
>   "resource_limits": {
>     "nvidia.com/gpu": 1
>   },
>   "env": [
>     {
>       "name": "OMNI_USER",
>       "valueFrom": {
>         "secretKeyRef": {
>           "key": "OMNI_USER",
>           "name": "nucleus-secret"
>         }
>       }
>     },
>     {
>       "name": "OMNI_PASS",
>       "valueFrom": {
>         "secretKeyRef": {
>           "key": "OMNI_PASS",
>           "name": "nucleus-secret"
>         }
>       }
>     }
>   ]
> },
> ...
> ```
> Alternatively, if security is not a concern, you may include the username and password directly through the `env` entry.

Upload the custom Isaac Sim script to Omniverse Nucleus. For an example,
upload `tasks/isaac-sim-simulation-example.py` to
`omniverse://$NUCLEUS_HOSTNAME/Projects/J3soon/Isaac/2023.1.1/Scripts/` through the GUI.

Alternatively, use [`omnicli`](https://docs.omniverse.nvidia.com/connect/latest/connect-sample.html#omni-cli) to upload the script to Nucleus:

```sh
cd thirdparty/omnicli
./omnicli copy "../../tasks/isaac-sim-simulation-example.py" "omniverse://$NUCLEUS_HOSTNAME/Projects/J3soon/Isaac/2023.1.1/Scripts/isaac-sim-simulation-example.py"
```

Save the job definition file and verify it:

```sh
source secrets/env.sh
scripts/save_job.sh isaac-sim-output-example
scripts/load_job.sh
```

Then, submit the job:

```sh
scripts/submit_task.sh isaac-sim-output-example \
"/run.sh \
  --download-src 'omniverse://$NUCLEUS_HOSTNAME/Projects/J3soon/Isaac/2023.1.1/Scripts/isaac-sim-simulation-example.py' \
  --download-dest '/src/isaac-sim-simulation-example.py' \
  --upload-src '/results/isaac-sim-simulation-example.txt' \
  --upload-dest 'omniverse://$NUCLEUS_HOSTNAME/Projects/J3soon/Isaac/2023.1.1/Results/isaac-sim-simulation-example.txt' \
  './python.sh -u /src/isaac-sim-simulation-example.py 10'" \
  "Isaac Sim Cube Fall"
```

You can remove the job definition file after the job has finished:

```sh
scripts/remove_job.sh isaac-sim-output-example
```

This demo allows running arbitrary Isaac Sim scripts on Omniverse Farm by downloading the necessary files, executing the specified command, and then uploading the output files to Nucleus.

> This and the following examples assume that there is no external volume mounted to the container. You could skip the `--download-src` and `--upload-dest` options if you have a persistent volume mounted to the container.

## Running Omniverse Isaac Gym Scripts

> Make sure to follow the **Running Custom Isaac Sim Scripts** section before moving on to this section.

Upload the Omniverse Isaac Gym repo code to Omniverse Nucleus. Specifically,
download and upload [NVIDIA-Omniverse/OmniIsaacGymEnvs](https://github.com/NVIDIA-Omniverse/OmniIsaacGymEnvs) to
`omniverse://$NUCLEUS_HOSTNAME/Projects/J3soon/Isaac/2023.1.1/Scripts/` through the GUI.

Alternatively, use [`omnicli`](https://docs.omniverse.nvidia.com/connect/latest/connect-sample.html#omni-cli) to upload the repo to Nucleus:

```sh
apt-get update && apt-get install -y git
# download omniverse isaac gym
git clone https://github.com/NVIDIA-Omniverse/OmniIsaacGymEnvs.git
cd OmniIsaacGymEnvs
git reset --hard release/2023.1.1
cd ..
# upload
cd thirdparty/omnicli
./omnicli copy "../../OmniIsaacGymEnvs" "omniverse://$NUCLEUS_HOSTNAME/Projects/J3soon/Isaac/2023.1.1/Scripts/OmniIsaacGymEnvs"
```

Save the job definition file and verify it:

```sh
source secrets/env.sh
scripts/save_job.sh isaac-sim-output-example
scripts/load_job.sh
```

Then, submit the job:

```sh
scripts/submit_task.sh isaac-sim-output-example \
"/run.sh \
  --download-src 'omniverse://$NUCLEUS_HOSTNAME/Projects/J3soon/Isaac/2023.1.1/Scripts/OmniIsaacGymEnvs' \
  --download-dest '/src/OmniIsaacGymEnvs' \
  --upload-src '/src/OmniIsaacGymEnvs/omniisaacgymenvs/runs' \
  --upload-dest 'omniverse://$NUCLEUS_HOSTNAME/Projects/J3soon/Isaac/2023.1.1/Results/OmniIsaacGymEnvs/runs' \
  './python.sh -u -m pip install -e /src/OmniIsaacGymEnvs' \
  './python.sh -u /src/OmniIsaacGymEnvs/omniisaacgymenvs/scripts/rlgames_train.py task=Cartpole headless=True'" \
  "Omniverse Isaac Gym Cartpole"
```

You can remove the job definition file after the job has finished:

```sh
scripts/remove_job.sh isaac-sim-output-example
```

This demo allows running arbitrary Omniverse Isaac Gym scripts on Omniverse Farm by downloading the necessary files, executing the specified commands, and then uploading the output checkpoint files to Nucleus.

## Running Omniverse Isaac Gym Scripts with SKRL

> Make sure to follow the **Running Custom Isaac Sim Scripts** section before moving on to this section.

Upload the Omniverse Isaac Gym repo code and SKRL repo code to Omniverse Nucleus. Specifically,
download and upload [NVIDIA-Omniverse/OmniIsaacGymEnvs](https://github.com/NVIDIA-Omniverse/OmniIsaacGymEnvs) and [Toni-SM/skrl](https://github.com/Toni-SM/skrl) to
`omniverse://$NUCLEUS_HOSTNAME/Projects/J3soon/Isaac/2023.1.1/Scripts/oige-and-skrl/` through the GUI.

Then, upload the SKRL training script to Omniverse Nucleus. For an example,
upload `tasks/skrl-examples` to
`omniverse://$NUCLEUS_HOSTNAME/Projects/J3soon/Isaac/2023.1.1/Scripts/oige-and-skrl/` through the GUI.

Alternatively, use [`omnicli`](https://docs.omniverse.nvidia.com/connect/latest/connect-sample.html#omni-cli) to upload the repos to Nucleus:

```sh
apt-get update && apt-get install -y git
# download omniverse isaac gym
git clone https://github.com/NVIDIA-Omniverse/OmniIsaacGymEnvs.git
cd OmniIsaacGymEnvs
git reset --hard release/2023.1.1
cd ..
# download skrl
git clone https://github.com/Toni-SM/skrl.git
cd skrl
git reset --hard 1.1.0
cd ..
# upload
cd thirdparty/omnicli
./omnicli copy "../../OmniIsaacGymEnvs" "omniverse://$NUCLEUS_HOSTNAME/Projects/J3soon/Isaac/2023.1.1/Scripts/oige-and-skrl/OmniIsaacGymEnvs"
./omnicli copy "../../skrl" "omniverse://$NUCLEUS_HOSTNAME/Projects/J3soon/Isaac/2023.1.1/Scripts/oige-and-skrl/skrl"
./omnicli copy "../../tasks/skrl-examples" "omniverse://$NUCLEUS_HOSTNAME/Projects/J3soon/Isaac/2023.1.1/Scripts/oige-and-skrl/skrl-examples"
```

Save the job definition file and verify it:

```sh
source secrets/env.sh
scripts/save_job.sh isaac-sim-output-example
scripts/load_job.sh
```

Then, submit the job:

```sh
scripts/submit_task.sh isaac-sim-output-example \
"/run.sh \
  --download-src 'omniverse://$NUCLEUS_HOSTNAME/Projects/J3soon/Isaac/2023.1.1/Scripts/oige-and-skrl' \
  --download-dest '/src' \
  --upload-src '/isaac-sim/runs' \
  --upload-dest 'omniverse://$NUCLEUS_HOSTNAME/Projects/J3soon/Isaac/2023.1.1/Results/oige-and-skrl/runs' \
  './python.sh -u -m pip install -e /src/OmniIsaacGymEnvs' \
  './python.sh -u -m pip install --upgrade pip' \
  './python.sh -u -m pip install -e /src/skrl["torch"]' \
  'apt-get update' \
  'apt-get install -y libglib2.0-0 libsm6 libxrender1 libxext6' \
  './python.sh -u /src/skrl-examples/omniisaacgym/torch_ant_ppo_headless.py'" \
  "Omniverse Isaac Gym and SKRL Torch Ant PPO"
```

> Note that the `pip install --upgrade pip` command is necessary to install the SKRL package.
>
> Note that the packages installed by `apt-get` is to prevent the following error:
> ```
> ImportError: libgthread-2.0.so.0: cannot open shared object file: No such file or directory
> ```
>
> See [this post](https://stackoverflow.com/a/62786543) for further information.

You can remove the job definition file after the job has finished:

```sh
scripts/remove_job.sh isaac-sim-output-example
```

This demo allows running arbitrary Omniverse Isaac Gym scripts on Omniverse Farm by downloading the necessary files, executing the specified commands, and then uploading the output checkpoint files to Nucleus.

## Running Isaac Sim Jobs Locally During Development

For headless tasks, simply follow [the official guide](https://docs.omniverse.nvidia.com/isaacsim/latest/installation/install_container.html).

If your task requires a GUI during development, see [this guide](https://github.com/j3soon/isaac-extended#docker-container-with-display).

## Developer Notes

- The job definitions used above contains minimal configuration. You can include more configuration options by referring to the [Job Definition Docs](https://docs.omniverse.nvidia.com/farm/latest/guides/creating_job_definitions.html) and the [Farm Examples](https://docs.omniverse.nvidia.com/farm/latest/farm_examples.html).
- The sample job definition files and the `scripts/save_job.sh` script only allows the use of a single argument `args`. You need to modify the job definition file and script to include more arguments if necessary.
- Saving an updated job definition (`scripts/save_job.sh`) and submitting a task that refers to that job definition (`scripts/submit_task.sh`) doesn't seem to be always in sync. Please make sure to remove the job definition (`scripts/remove_job.sh`) first, and submit some dummy tasks to verify that the job definition changes are reflected in new tasks before submitting the actual task.
- The default time limit (`active_deadline_seconds`) for K8s pods are set to `86400` (1 day) by Omniverse Farm. If the task takes longer than 1 day, the task will be terminated. After the K8s pod has been terminated, the K8s job will restart it once (`backoffLimit: 1`) even though `is_retryable` is set to False. This restarted K8s pod cannot be cancelled through the Omniverse UI. You can modify the time limit by changing the `active_deadline_seconds` field in the job definition file, we set it to 10 days in all job definitions, which is enough for most tasks.
- The `job_spec_path` is required for options such as `args` and `env` to be saved. If the `job_spec_path` is `null`, these options will be forced empty. In our examples, we simply set it to a dummy value (`"null"`). See [this thread](https://nvidia.slack.com/archives/C03AZDA710T/p1689869120574269) for more details.
- If relative paths are not setup correctly, the task might fail due to the behavior of automatically prepending the path with the current working directory (`/isaac-sim`). This behavior may result in errors such as:
  ```
  /isaac-sim/kit/python/bin/python3: can't open file '/isaac-sim/ ': [Errno 2] No such file or directory`.
  ```
- Not sure why uploading files to Nucleus in docker using `omnicli` sometimes results in connection error: `Error: Connection`.

## References

- [Omniverse Farm Documentation](https://docs.omniverse.nvidia.com/farm/latest/index.html)
