# Troubleshooting

Start with:

```bash
cd /srv/dgx-ai
bash scripts/doctor.sh
bash scripts/diagnostics.sh
```

## ComfyUI service missing

If `dgx-comfy.service` does not exist, the install stopped before the systemd-unit step. Do not delete the environment blindly. Inspect the error first.

## `nvidia-cusparselt-cu13 0.8.1 is not supported on this platform`

The v0.1 installer only tolerates this exact warning after dependencies are installed. It then requires real CUDA and Triton initialization tests to pass. Any other `pip check` error remains fatal.

## Triton / GCC compilation failure

Check that compiler and Python development headers exist:

```bash
gcc --version
python3 -c 'import sysconfig; print(sysconfig.get_path("include"))'
ls "$(python3 -c 'import sysconfig; print(sysconfig.get_path("include"))')/Python.h"
```

Then run:

```bash
sudo -u dgx-comfy env HOME=/srv/dgx-ai/comfy \
  /srv/dgx-ai/comfy/venv/bin/python /srv/dgx-ai/scripts/check_triton.py
```

Do not reinstall NVIDIA drivers at random.

## Image works in ComfyUI but not Open WebUI

1. Run `python3 scripts/test-image.py`.
2. Verify the mappings in `docs/OPENWEBUI.md`.
3. For the abliterated image preset use **Legacy** function calling.
4. Watch `sudo journalctl -u dgx-comfy -f -o cat`.

If ComfyUI never logs `got prompt`, Open WebUI did not submit the workflow.

## Internet page says Access Denied

That is often the remote site's anti-bot layer, not a Qwen3 failure. Ensure the Internet preset uses Native tools and instruct it to fall back to another source rather than claiming it read the blocked page.
