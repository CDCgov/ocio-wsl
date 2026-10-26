"""Check config/config.toml and the update-config.sh output it is generated from.

Run with: uv run --locked pytest -q
"""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import tomllib
import unittest

REPO = Path(__file__).resolve().parents[1]
CONFIG = REPO / "config" / "config.toml"


def check_tools(test, config):
    tools = config["tools"]
    test.assertTrue(tools, "[tools] is empty")
    for name, spec in tools.items():
        with test.subTest(tool=name):
            if isinstance(spec, dict):
                test.assertIsInstance(spec.get("version"), str)
                depends = spec.get("depends", [])
                # A YAML-rendered array ("- python") comes through as a string
                test.assertIsInstance(depends, list)
                for dependency in depends:
                    test.assertIn(dependency, tools)
            else:
                test.assertIsInstance(spec, str)


class ConfigTests(unittest.TestCase):
    def test_config_is_valid(self):
        with CONFIG.open("rb") as file:
            check_tools(self, tomllib.load(file))

    @unittest.skipUnless(shutil.which("yq"), "yq is required by update-config.sh")
    def test_update_config_output_is_valid(self):
        with tempfile.TemporaryDirectory(prefix="cdc-config-") as temp:
            root = Path(temp)
            bin_dir = root / "bin"
            bin_dir.mkdir()
            # Stub mise so the test is offline; "latest" fails, keeping current versions
            mise = bin_dir / "mise"
            mise.write_text("#!/bin/bash\nexit 1\n")
            mise.chmod(0o755)
            output = root / "config.toml.latest"
            subprocess.run(["bash", str(REPO / "update-config.sh"), str(CONFIG), str(output)],
                           env=os.environ | {"PATH": f"{bin_dir}:{os.environ['PATH']}"},
                           check=True, capture_output=True, timeout=60)
            with CONFIG.open("rb") as file:
                original = tomllib.load(file)
            with output.open("rb") as file:
                updated = tomllib.load(file)
            check_tools(self, updated)
            self.assertEqual(updated, original)


if __name__ == "__main__":
    unittest.main()
