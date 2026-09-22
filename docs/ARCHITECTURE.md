# Architecture

```text
Browser
  |
  | SSH tunnel / future HTTPS reverse proxy
  v
Open WebUI :8080 (127.0.0.1)
  |-- Ollama :11434 (127.0.0.1)
  |     |-- cyber-reference
  |     |-- cyber-libre
  |     |-- discussion-libre
  |     `-- internet-reference
  |
  `-- ComfyUI :8188 (127.0.0.1)
        `-- Z-Image-Turbo
```

Open WebUI and Ollama run with Docker Compose using host networking. ComfyUI is a dedicated unprivileged systemd service in v0.1 because that is the stack actually qualified on DGX Spark.

The user-facing interface is Open WebUI. ComfyUI is a backend and should not be exposed directly to untrusted networks.
