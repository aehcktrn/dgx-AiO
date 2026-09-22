# Installation

## Prerequisites

- NVIDIA DGX Spark / ARM64;
- DGX OS with the NVIDIA driver/runtime working;
- Internet access for initial container/model downloads;
- an administrator account with `sudo`;
- recommended: at least ~180 GiB free before downloading all v0.1 models.

## Install

```bash
git clone https://github.com/aehcktrn/dgx-AiO.git
cd dgx-AiO
bash install.sh
```

Do not run `sudo bash install.sh`.

The installer copies the project to `/srv/dgx-ai`, installs host build prerequisites, resolves container digests, downloads the Ollama profiles and image weights, creates the ComfyUI service, and runs smoke tests.

## First connection

The installer writes temporary credentials to:

```text
/srv/dgx-ai/.bootstrap-password
```

Open WebUI binds to loopback. From another workstation:

```bash
ssh -L 8080:127.0.0.1:8080 USER@SPARK_IP
```

Then open `http://127.0.0.1:8080`.

Change the admin password, then run:

```bash
cd /srv/dgx-ai
bash scripts/05-clear-bootstrap.sh
```

Finally configure the Workspace presets described in [`OPENWEBUI.md`](OPENWEBUI.md).
