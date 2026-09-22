#!/usr/bin/env python3
"""Test CUDA reel et court, sans telechargement de modele."""
import json
import torch
if not torch.cuda.is_available():
    raise SystemExit("CUDA indisponible dans cet environnement Python.")
a=torch.randn((512,512),device='cuda')
b=a @ a
value=b.mean().item()
torch.cuda.synchronize()
print(json.dumps({'torch':torch.__version__,'cuda':torch.version.cuda,
                  'gpu':torch.cuda.get_device_name(0),
                  'capability':torch.cuda.get_device_capability(0),
                  'matmul_result':value},indent=2))
