# Open WebUI configuration — v0.1

The core services are installed automatically. The v0.1 release keeps Workspace preset creation manual on purpose: we have validated these settings in the UI, but not a stable supported API for creating them programmatically.

## 1. ComfyUI image backend

Admin → Experience → Images:

- Engine: **ComfyUI**
- Base URL: `http://127.0.0.1:8188`
- Workflow: import `workflows/z-image-turbo.api.json`
- Model: `z_image_turbo_bf16.safetensors`

Workflow mapping:

| Parameter | Node ID | Key |
|---|---:|---|
| Prompt | `4` | `text` |
| Model | `1` | `unet_name` |
| Width | `6` | `width` |
| Height | `6` | `height` |
| Steps | `8` | `steps` |
| Seed | `8` | `seed` |

The model entry deliberately maps to `UNETLoader.unet_name`; this workflow does not use `CheckpointLoaderSimple.ckpt_name`.

## 2. Workspace model: Discussion Libre

- Base model: `discussion-libre:latest`
- General chat only.
- Recommended temperature: `0.4`.

## 3. Workspace model: Discussion Libre & Images

- Base model: `discussion-libre:latest`
- Function calling: **Legacy**
- Capability: Image Generation = enabled
- Capability: Builtin Tools = enabled
- Default Features: Image Generation = enabled
- Builtin Tools: Image Generation = enabled
- System prompt: paste `config/openwebui/prompts/discussion-images.txt`

Why Legacy? During qualification, the abliterated discussion model did not reliably emit the native `generate_image` tool call. Legacy mode successfully submitted the workflow to ComfyUI.

## 4. Workspace model: Qwen3 - Internet

- Base model: `internet-reference:latest`
- Function calling: **Native**
- Capability: Web Search = enabled
- Capability: Builtin Tools = enabled
- Default Features: Web Search = enabled
- Builtin Tools: Web Search = enabled
- System prompt: paste `config/openwebui/prompts/internet.txt`

Admin → Web Search:

- Enable Web Search.
- DuckDuckGo/DDGS is a convenient no-key starting point.
- Start with roughly 5 results.

The container also gets a browser-like `USER_AGENT` to reduce trivial 403s. Some sites behind Akamai/Cloudflare will still reject automated fetching; the prompt instructs Qwen3 to use another source instead of hallucinating access.

## 5. Validation

Image path:

```bash
python3 scripts/test-image.py
sudo journalctl -u dgx-comfy -f -o cat
```

Internet tool calling:

```bash
python3 scripts/test-tools.py --model internet-reference
bash scripts/test-web-egress.sh
```

Chat:

```bash
python3 scripts/test-chat.py --model discussion-libre
```
