# Security policy

This project exposes local AI services and is intended to remain bound to loopback by default.

## Please do not

- publish Ollama, ComfyUI or Open WebUI APIs directly to the Internet;
- mount `/var/run/docker.sock`, SSH keys or the host root filesystem into the AI services;
- give an abliterated model an unrestricted privileged shell;
- execute untrusted malware samples inside the inference environment.

For dynamic malware analysis or autonomous red-team experimentation, use a separate isolated lab boundary.

## Reporting a vulnerability

Prefer a GitHub private security advisory for sensitive reports. If private reporting is unavailable, open a minimal issue without exploit details and request a private contact channel.
