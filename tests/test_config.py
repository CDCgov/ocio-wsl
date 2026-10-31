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
        self.check_update("exit 1", updated_versions=False)

    @unittest.skipUnless(shutil.which("yq"), "yq is required by update-config.sh")
    def test_update_config_uses_release_age_and_preserves_options(self):
        self.check_update('''[ "$1" = latest ] || exit 99
[ "$2" = --minimum-release-age ] || exit 99
[ "$3" = 14d ] || exit 99
[ "$#" = 4 ] || exit 99
echo 99.0.0''', updated_versions=True)

    @unittest.skipUnless(shutil.which("yq"), "yq is required by update-config.sh")
    def test_update_config_keeps_pins_for_empty_lookup(self):
        self.check_update("exit 0", updated_versions=False)

    def check_update(self, mise_script, *, updated_versions):
        with tempfile.TemporaryDirectory(prefix="cdc-config-") as temp:
            root = Path(temp)
            bin_dir = root / "bin"
            bin_dir.mkdir()
            # Stub mise to exercise version resolution without network access.
            mise = bin_dir / "mise"
            mise.write_text(f"#!/bin/bash\n{mise_script}\n")
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
            if updated_versions:
                for name, spec in original["tools"].items():
                    if isinstance(spec, dict):
                        spec["version"] = "99.0.0"
                    else:
                        original["tools"][name] = "99.0.0"
            self.assertEqual(updated, original)


if __name__ == "__main__":
    unittest.main()
