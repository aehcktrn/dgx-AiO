# dgx-AiO

**All-in-One DGX Spark autoconfig for cyber feignasses.**

`dgx-AiO` is a reproducible local-AI stack for NVIDIA DGX Spark, focused on local chat, cyber/red-team assistance, an abliterated discussion profile, Qwen3 Internet, and local image generation with ComfyUI + Z-Image-Turbo.

> Status: **v0.1.x / bootstrap**. This repository captures what was actually validated on a DGX Spark before we start making the installer clever.

## Quick start

```bash
git clone https://github.com/aehcktrn/dgx-AiO.git
cd dgx-AiO
bash install.sh
```

Do **not** run `sudo bash install.sh`.

A fresh install now ends with the standard automated acceptance suite. The backend stack is considered installed only if that suite passes.

## Verification

```bash
cd /srv/dgx-ai
bash scripts/verify.sh --quick   # health, inventory, bindings
bash scripts/verify.sh           # + inference, tools, web, real image
bash scripts/verify.sh --full    # + restart recovery and backup integrity
```

Each run produces a machine-readable JSON report and detailed log under `state/`. See [`docs/TESTING.md`](docs/TESTING.md).

## What gets installed

| Component | Role |
|---|---|
| Ollama | Local LLM runtime |
| Open WebUI | User-facing chat interface |
| ComfyUI | Local image-generation backend |
| Qwen3-Coder 30B A3B | Cyber/reference assistant |
| Huihui Qwen3-Coder abliterated | Cyber profile with reduced refusals |
| Huihui Qwen3 30B abliterated | General discussion profile |
| Qwen3 30B A3B Instruct 2507 | Internet/native-tools profile |
| BGE-M3 | Local embeddings |
| Z-Image-Turbo | Text-to-image workflow |

## Important design choices

- Services bind to `127.0.0.1` by default.
- Ollama cloud functions are disabled.
- ComfyUI custom nodes and external API nodes are disabled in v0.1.
- Image generation uses Open WebUI **Legacy** function-calling with the abliterated discussion model because Native image tool calls were unreliable during qualification.
- The Internet profile uses the original Qwen3 Instruct model and **Native** tool calling.
- Web search can reach the Internet. Local inference does not mean network isolation.
- Image editing / inpainting / vision are not part of v0.1 yet.

## After installation

Read [`docs/OPENWEBUI.md`](docs/OPENWEBUI.md). Workspace preset creation remains manual in v0.1 and is the main remaining E2E test gap.

## Security / cyber use

The stack is intended for legitimate administration, development, education, defensive security and authorized red-team / lab activity. It does not grant the LLM a privileged shell or autonomous target access by default.

See [`SECURITY.md`](SECURITY.md).

## License

🍺 **Beerware.** Do whatever you want with it. Keep the notice somewhere in the source if you redistribute it.

If dgx-AiO saved you from spending your weekend debugging ARM64, CUDA, Triton and ComfyUI on a DGX Spark, buy me a beer if we ever meet.

No warranty. If it sets your Spark on fire, that's between you and NVIDIA.

See [`LICENSE`](LICENSE).
