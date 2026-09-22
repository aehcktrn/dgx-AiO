#!/usr/bin/env python3
from __future__ import annotations
import json
import sysconfig
from pathlib import Path
import torch
import triton
from triton.runtime import driver

header = Path(sysconfig.get_path("include")) / "Python.h"
if not header.is_file():
    raise SystemExit(f"Python development header missing: {header}")
if not torch.cuda.is_available():
    raise SystemExit("CUDA is not available to PyTorch")
torch.cuda.init()
device = driver.active.get_current_device()
print(json.dumps({
    "python_header": str(header),
    "torch": torch.__version__,
    "cuda": torch.version.cuda,
    "triton": triton.__version__,
    "gpu": torch.cuda.get_device_name(0),
    "triton_device": str(device),
}, indent=2))
