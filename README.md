# dgx-AiO

**All-in-One DGX Spark autoconfig for cyber feignasses.**

`dgx-AiO` is a reproducible local-AI stack for NVIDIA DGX Spark, focused on:

- local chat with Ollama + Open WebUI;
- a cyber / red-team oriented reference model;
- an abliterated cyber profile for fewer refusals during legitimate lab work;
- a general-purpose abliterated discussion profile;
- a Qwen3 Internet profile with native tool calling for web search;
- local image generation with ComfyUI + Z-Image-Turbo;
- diagnostics, smoke tests and backup helpers.

> Status: **v0.1.x / bootstrap**. This repository captures what was actually validated on a DGX Spark before we start making the installer clever.

## Quick start

On the DGX Spark:

```bash
git clone https://github.com/aehcktrn/dgx-AiO.git
cd dgx-AiO
bash install.sh
```

Do **not** run `sudo bash install.sh`. The scripts request privilege only where needed.

When the installer finishes, it prints the local admin bootstrap credentials and the SSH tunnel command to reach Open WebUI.

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
- Image generation currently uses Open WebUI **Legacy** function-calling mode because the abliterated discussion model did not reliably emit native image tool calls during qualification.
- The Internet profile uses the original Qwen3 Instruct model and **Native** tool calling.
- Web search can reach the Internet. Local inference does not mean network isolation.
- Image editing / inpainting / vision are not part of v0.1 yet.

## After installation

Read [`docs/OPENWEBUI.md`](docs/OPENWEBUI.md). The v0.1 installer deliberately does not mutate Open WebUI's internal database to create presets automatically; those mappings are documented and will be automated only after the API path is qualified.

Useful commands:

```bash
cd /srv/dgx-ai
bash scripts/doctor.sh
python3 scripts/test-chat.py --model cyber-reference
python3 scripts/test-image.py
bash scripts/test-web-egress.sh
bash scripts/backup.sh
```

## Project principles

1. Reproduce first, optimize second.
2. Pin versions we have qualified.
3. Never silently replace a model or container tag during a normal reboot.
4. Fail closed on unknown dependency errors; allow only explicit, documented compatibility exceptions.
5. Keep chat freedom separate from autonomous execution privileges.

## Security / cyber use

The stack is intended for legitimate administration, development, education, defensive security and authorized red-team / lab activity. It does not grant the LLM a privileged shell or autonomous target access by default.

See [`SECURITY.md`](SECURITY.md).

## License

No software license has been selected yet. Until a license is added, normal copyright rules apply to this repository.
