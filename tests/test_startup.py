"""Run startup scripts in temporary fixtures without changing OS accounts.

Only absolute deployment paths are redirected; script control flow is unchanged.
Run with: uv run --locked pytest -q
"""
import configparser
import fcntl
import os
from pathlib import Path
import shlex
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]


class StartupTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="cdc-startup-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.home = self.root / "home"
        self.home.mkdir()
        self.account = self.root / "account"
        self.account.touch()
        self.state = self.root / "state"
        self.password_hash = self.root / "password-hash"
        self.password_hash.write_text("!!")
        self.password_calls = self.root / "password-calls"
        self.log = self.root / "calls"
        self.conf = self.root / "wsl.conf"
        self.conf.write_text("[boot]\nsystemd=true\n")
        self.env = os.environ | {"PATH": f"{self.bin}:{os.environ['PATH']}"}
        self.username = subprocess.check_output(["id", "-un"], text=True).strip()
        self.executable("getent", f'''
if [ "$1" = shadow ] && [ -e {shlex.quote(str(self.account))} ]; then
  printf '{self.username}:%s:0:0:99999:7:::\n' "$(cat {shlex.quote(str(self.password_hash))})"
elif [ "$1" = passwd ] && [ -e {shlex.quote(str(self.account))} ]; then
  echo '{self.username}:x:1000:1000::{self.home}:/bin/bash'
else
  exit 2
fi''')
        # Only the setup script's root check is simulated. File operations run
        # with the real invoking user's permissions inside this fixture.
        self.executable("id", 'if [ "$1" = -u ]; then echo 0; else /usr/bin/id "$@"; fi')
        self.helper = self.executable("create-default-user.sh", "exit 0")
        for name in ("install-user-tools.sh", "setup-user-workspace.sh", "configure-rootless-podman.sh"):
            self.setup_step(name)

    def executable(self, name, body):
        path = self.bin / name
        path.write_text("#!/bin/bash\n" + body + "\n")
        path.chmod(0o755)
        return path

    def setup_step(self, name, status=0):
        self.executable(name, f"echo {shlex.quote(name)} >> {shlex.quote(str(self.log))}\nexit {status}")

    def run_script(self, relative, *args, replacements=None, input=""):
        source = (REPO / relative).read_text()
        paths = {
            "/opt/scripts/": str(self.bin) + "/",
            "/run/lock/cdc-default-user.lock": str(self.root / "lock"),
            "/etc/wsl.conf": str(self.conf),
            "/var/lib/cdc-wsl": str(self.state),
        } | (replacements or {})
        for old, new in paths.items():
            source = source.replace(old, new)
        script = self.root / "script.sh"
        script.write_text(source)
        return subprocess.run(["bash", str(script), *args], env=self.env,
                              input=input, text=True, capture_output=True, timeout=10)

    def test_import_missing_username_is_failure(self):
        self.executable(self.helper.name, "exit 3")
        result = self.run_script("scripts/run-once.sh")
        self.assertEqual(result.returncode, 3)
        self.assertIn("as root", result.stderr)

    def test_boot_retries_can_recover(self):
        self.executable(self.helper.name, "exit 3")
        self.assertNotEqual(self.run_script("scripts/run-once.sh").returncode, 0)
        self.executable(self.helper.name, "exit 0")
        self.assertEqual(self.run_script("scripts/run-once.sh").returncode, 0)

    def test_optional_failures_do_not_skip_workspace_or_default_user(self):
        for failed in ("install-user-tools.sh", "configure-rootless-podman.sh", "setup-user-workspace.sh"):
            with self.subTest(failed=failed):
                self.log.unlink(missing_ok=True)
                self.setup_step(failed, 1)
                result = self.run_script("scripts/create-default-user.sh")
                self.assertEqual(result.returncode, 1, result.stderr)
                self.assertIn(f"default={self.username}", self.conf.read_text())
                self.assertEqual(len(self.log.read_text().splitlines()), 3)
                self.setup_step(failed)
        self.assertEqual(self.run_script("scripts/create-default-user.sh").returncode, 0)
        self.assertEqual(self.conf.read_text().count("[user]"), 1)

    def test_oobe_does_not_prompt_after_account_exists(self):
        self.executable(self.helper.name, "exit 1")
        result = self.run_script("config/oobe.sh")
        self.assertEqual(result.returncode, 1)
        self.assertNotIn("Please create", result.stdout)
        self.assertIn("account exists", result.stderr)

    def test_oobe_prompts_when_no_account_exists(self):
        self.account.unlink()
        self.executable(self.helper.name, 'if [ "$#" -gt 0 ]; then exit 0; else exit 3; fi')
        result = self.run_script("config/oobe.sh", input="developer\n")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Please create", result.stdout)

    def test_missing_windows_username_and_unexpanded_variable_are_rejected(self):
        self.account.unlink()
        cmd = self.executable("cmd.exe", "exit 1")
        replacements = {"/mnt/c/windows/system32/cmd.exe": str(cmd)}
        for body in ("exit 1", "echo '%USERNAME%'"):
            cmd.write_text("#!/bin/bash\n" + body + "\n")
            result = self.run_script("scripts/create-default-user.sh", replacements=replacements)
            self.assertEqual(result.returncode, 3, result.stderr)

    def workspace(self, windows):
        return self.run_script("scripts/setup-user-workspace.sh", self.username, str(windows))

    def test_workspace_recovers_when_windows_becomes_available(self):
        windows = self.root / "Windows profile"
        first = self.workspace(windows)
        self.assertEqual(first.returncode, 0, first.stderr)
        shared = self.home / "shared"
        self.assertTrue(shared.is_dir())
        windows.mkdir()
        second = self.workspace(windows)
        self.assertEqual(second.returncode, 0, second.stderr)
        self.assertTrue(shared.is_symlink())
        self.assertEqual(shared.resolve(), windows / "wsl-shared")
        self.assertTrue((self.home / "code/cdc").is_dir())
        self.assertEqual(self.workspace(windows).returncode, 0)

    def test_workspace_preserves_local_files_including_hidden_files(self):
        windows = self.root / "windows"
        self.workspace(windows)
        keep = self.home / "shared/.keep"
        keep.write_text("local work")
        windows.mkdir()
        result = self.workspace(windows)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse((self.home / "shared").is_symlink())
        self.assertEqual(keep.read_text(), "local work")

    def test_workspace_preserves_existing_symlink(self):
        target = self.root / "other"
        (self.home / "shared").symlink_to(target)
        windows = self.root / "windows"
        windows.mkdir()
        self.assertEqual(self.workspace(windows).returncode, 0)
        self.assertEqual(os.readlink(self.home / "shared"), str(target))

    def test_nonlogin_shell_loads_certificate_environment_once(self):
        rc = self.root / "bashrc"
        rc.write_text((REPO / "config/.bashrc").read_text().replace(
            "/etc/profile.d/cdc-env.sh", str(REPO / "config/cdc-env.sh")))
        result = subprocess.run([
            "/usr/bin/env", "-i", f"HOME={self.home}", "PATH=/usr/bin:/bin", "TERM=dumb",
            "bash", "--noprofile", "--rcfile", str(rc), "-ic",
            '. "$1"; test -s "$SSL_CERT_FILE" && test -s "$REQUESTS_CA_BUNDLE" '
            '&& test -s "$PIP_CERT" && test -s "$CURL_CA_BUNDLE" '
            '&& test "$NODE_OPTIONS" = --use-openssl-ca', "bash", str(rc),
        ], capture_output=True, text=True, timeout=10)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_service_retries_are_bounded(self):
        service = configparser.ConfigParser(strict=False)
        service.read(REPO / "config/run-once.service")
        self.assertEqual(service["Service"]["Restart"], "on-failure")
        self.assertGreater(service.getint("Service", "RestartSec"), 0)
        self.assertGreater(service.getint("Unit", "StartLimitBurst"), 0)
        self.assertEqual(service["Unit"]["StartLimitIntervalSec"], "infinity")
        self.assertGreater(service.getint("Service", "TimeoutStartSec"), 0)
        self.assertGreater(service.getint("Service", "TimeoutStopSec"), 0)

    def prepare_new_account(self, useradd_status=0, password_status=0):
        self.account.unlink(missing_ok=True)
        useradd = self.executable("useradd", f"touch {shlex.quote(str(self.account))}\nexit {useradd_status}")
        self.password_command(password_status)
        return {"/usr/sbin/useradd": str(useradd)}

    def password_command(self, status):
        self.executable("passwd", f"echo called >> {shlex.quote(str(self.password_calls))}\n"
                        f"if [ {status} -ne 0 ]; then exit {status}; fi\n"
                        f": > {shlex.quote(str(self.password_hash))}")

    def test_password_failure_remains_failure_until_recovered(self):
        replacements = self.prepare_new_account(password_status=1)
        for _ in range(2):
            result = self.run_script("scripts/create-default-user.sh", self.username, replacements=replacements)
            self.assertEqual(result.returncode, 1, result.stderr)
            self.assertTrue((self.state / "pending-user-password").is_file())
        self.assertEqual(len(self.password_calls.read_text().splitlines()), 2)
        self.password_command(0)
        result = self.run_script("scripts/create-default-user.sh", replacements=replacements)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse((self.state / "pending-user-password").exists())
        self.assertEqual(self.password_hash.read_text(), "")
        self.assertIn(f"default={self.username}", self.conf.read_text())

    def test_retry_after_useradd_creates_account_but_returns_failure(self):
        replacements = self.prepare_new_account(useradd_status=1)
        result = self.run_script("scripts/create-default-user.sh", self.username, replacements=replacements)
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertTrue(self.account.exists())
        self.assertFalse(self.password_calls.exists())
        result = self.run_script("scripts/create-default-user.sh", replacements=replacements)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(self.password_calls.exists())

    def test_existing_account_password_is_untouched(self):
        self.password_command(1)
        self.password_hash.write_text("existing-password")
        result = self.run_script("scripts/create-default-user.sh")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(self.password_calls.exists())
        self.assertEqual(self.password_hash.read_text(), "existing-password")

    def test_password_changed_during_interrupted_setup_is_preserved(self):
        replacements = self.prepare_new_account(password_status=1)
        result = self.run_script("scripts/create-default-user.sh", self.username, replacements=replacements)
        self.assertEqual(result.returncode, 1, result.stderr)
        self.password_calls.unlink()
        for password in ("custom-password-hash", "!locked-password-hash", ""):
            with self.subTest(password=password):
                self.password_hash.write_text(password)
                (self.state / "pending-user-password").write_text(self.username + "\n")
                result = self.run_script("scripts/create-default-user.sh", replacements=replacements)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(self.password_hash.read_text(), password)
                self.assertFalse(self.password_calls.exists())
                self.assertFalse((self.state / "pending-user-password").exists())

    def test_mismatched_pending_account_is_not_modified(self):
        self.state.mkdir()
        (self.state / "pending-user-password").write_text("another-account\n")
        self.password_command(0)
        result = self.run_script("scripts/create-default-user.sh")
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertFalse(self.password_calls.exists())

    def test_single_character_initial_lock_is_initialized(self):
        replacements = self.prepare_new_account()
        self.password_hash.write_text("!")
        result = self.run_script("scripts/create-default-user.sh", self.username, replacements=replacements)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.password_hash.read_text(), "")
        self.assertFalse((self.state / "pending-user-password").exists())

    def test_waiting_for_another_setup_process_times_out(self):
        with (self.root / "lock").open("w") as lock:
            fcntl.flock(lock, fcntl.LOCK_EX)
            result = self.run_script("scripts/create-default-user.sh", replacements={
                "flock -w 35": "flock -w 0.1",
            })
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertIn("Timed out waiting", result.stderr)
        self.assertFalse(self.log.exists())

    def test_username_detection_kills_unresponsive_windows_command(self):
        self.account.unlink()
        cmd = self.executable("cmd.exe", "trap '' TERM; exec sleep 60")
        result = self.run_script("scripts/create-default-user.sh", replacements={
            "/mnt/c/windows/system32/cmd.exe": str(cmd),
            "--kill-after=2s 5s": "--kill-after=0.1s 0.1s",
        })
        self.assertEqual(result.returncode, 3, result.stderr)
        # The timed-out child must not retain the shared account setup lock.
        self.assertEqual(self.run_script("scripts/create-default-user.sh", replacements={
            "/mnt/c/windows/system32/cmd.exe": "/bin/false",
        }).returncode, 3)

    def test_workspace_detection_kills_unresponsive_windows_command(self):
        cmd = self.executable("cmd.exe", "trap '' TERM; exec sleep 60")
        self.executable("wslpath", "exit 1")
        result = self.run_script("scripts/setup-user-workspace.sh", self.username, replacements={
            "/mnt/c/Windows/System32/cmd.exe": str(cmd),
            "/mnt/c/windows/system32/cmd.exe": str(cmd),
            "--kill-after=2s 5s": "--kill-after=0.1s 0.1s",
        })
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue((self.home / "code/cdc").is_dir())
        self.assertTrue((self.home / "shared").is_dir())

    def launch_shell(self, cwd, *, nested=False, interactive=True):
        rc = self.root / "workspace-bashrc"
        rc.write_text((REPO / "config/.bashrc").read_text().replace(
            "/etc/profile.d/cdc-env.sh", str(REPO / "config/cdc-env.sh")
        ).replace("/mnt/[a-z]", str(self.root / "windows") + "/[a-z]"))
        env = {"HOME": str(self.home), "PATH": "/usr/bin:/bin", "TERM": "dumb",
               "SHLVL": "1" if nested else "0", "HISTFILE": "/dev/null"}
        if interactive:
            args = ["--rcfile", str(rc), "-ic", 'printf "DIRECTORY=%s\\n" "$PWD"']
        else:
            args = ["-c", '. "$1"; printf "DIRECTORY=%s\\n" "$PWD"', "bash", str(rc)]
        result = subprocess.run(["bash", "--noprofile", *args], env=env, cwd=cwd,
                                capture_output=True, text=True, timeout=10)
        self.assertEqual(result.returncode, 0, result.stderr)
        return next(line.removeprefix("DIRECTORY=") for line in result.stdout.splitlines()
                    if line.startswith("DIRECTORY="))

    def test_shell_starts_in_workspace_from_home_or_windows(self):
        workspace = self.home / "code/cdc"
        workspace.mkdir(parents=True)
        windows = self.root / "windows/c/Users/developer"
        windows.mkdir(parents=True)
        for directory in (self.home, self.root / "windows/c", windows):
            with self.subTest(directory=directory):
                self.assertEqual(self.launch_shell(directory), str(workspace))

    def test_shell_preserves_linux_project_directory(self):
        project = self.home / "code/cdc/project"
        project.mkdir(parents=True)
        self.assertEqual(self.launch_shell(project), str(project))

    def test_shell_preserves_nested_shell_directory(self):
        (self.home / "code/cdc").mkdir(parents=True)
        self.assertEqual(self.launch_shell(self.home, nested=True), str(self.home))

    def test_shell_preserves_noninteractive_command_directory(self):
        (self.home / "code/cdc").mkdir(parents=True)
        self.assertEqual(self.launch_shell(self.home, interactive=False), str(self.home))

    def test_shell_stays_put_when_workspace_is_missing(self):
        self.assertEqual(self.launch_shell(self.home), str(self.home))

    def test_dns_is_owned_by_wsl(self):
        config = configparser.ConfigParser()
        config.read(REPO / "config/wsl.conf")
        self.assertTrue(config.getboolean("network", "generateResolvConf"))
        # The boot helper must not overwrite WSL's resolver or query PowerShell.
        source = (REPO / "scripts/run-once.sh").read_text()
        self.assertNotIn("/etc/resolv.conf", source)
        self.assertNotIn("powershell.exe", source)


if __name__ == "__main__":
    unittest.main()
