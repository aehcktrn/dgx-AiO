from __future__ import annotations
import json
import os
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

class RepositoryConsistencyTests(unittest.TestCase):
    def test_version_matches_manifest(self):
        version = (ROOT / "VERSION").read_text().strip()
        manifest = (ROOT / "manifests" / "v0.1.0.yaml").read_text()
        match = re.search(r"^release:\s*(\S+)\s*$", manifest, re.MULTILINE)
        self.assertIsNotNone(match)
        self.assertEqual(version, match.group(1))

    def test_expected_runtime_files_exist(self):
        required = [
            "compose.yaml", "install.sh", "scripts/verify.sh", "scripts/doctor.sh",
            "scripts/test-image.py", "workflows/z-image-turbo.api.json", "docs/OPENWEBUI.md",
        ]
        for rel in required:
            self.assertTrue((ROOT / rel).is_file(), rel)

    def test_shell_scripts_are_executable(self):
        scripts = [ROOT / "install.sh", *sorted((ROOT / "scripts").glob("*.sh"))]
        for script in scripts:
            self.assertTrue(os.access(script, os.X_OK), str(script))

    def test_workflow_contract(self):
        flow = json.loads((ROOT / "workflows" / "z-image-turbo.api.json").read_text())
        expected = {
            "1": ("UNETLoader", "unet_name", "z_image_turbo_bf16.safetensors"),
            "2": ("CLIPLoader", "clip_name", "qwen_3_4b.safetensors"),
            "3": ("VAELoader", "vae_name", "ae.safetensors"),
            "4": ("CLIPTextEncode", "text", None),
            "6": ("EmptySD3LatentImage", "width", 1024),
            "8": ("KSampler", "steps", 8),
            "10": ("SaveImage", "filename_prefix", "DGX_Spark"),
        }
        for node_id, (kind, key, value) in expected.items():
            self.assertEqual(flow[node_id]["class_type"], kind)
            self.assertIn(key, flow[node_id]["inputs"])
            if value is not None:
                self.assertEqual(flow[node_id]["inputs"][key], value)

    def test_modelfiles_match_manifest_sources(self):
        manifest = (ROOT / "manifests" / "v0.1.0.yaml").read_text()
        for modelfile in sorted((ROOT / "modelfiles").glob("*.Modelfile")):
            first = next(line for line in modelfile.read_text().splitlines() if line.startswith("FROM "))
            source = first.split(maxsplit=1)[1]
            self.assertIn(source, manifest, modelfile.name)

    def test_loopback_and_cloud_defaults_present(self):
        compose = (ROOT / "compose.yaml").read_text()
        for expected in (
            "OLLAMA_HOST: 127.0.0.1:11434",
            "HOST: 127.0.0.1",
            'OLLAMA_NO_CLOUD: "1"',
            "COMFYUI_BASE_URL: http://127.0.0.1:8188",
            'ENABLE_OPENAI_API: "false"',
        ):
            self.assertIn(expected, compose)

if __name__ == "__main__":
    unittest.main()
