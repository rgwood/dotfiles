#!/usr/bin/env -S uv run --script --quiet
# /// script
# requires-python = ">=3.12"
# dependencies = []
# ///
"""Check bootstrap failures and shell PATHs without installing anything."""

import contextlib
import importlib.util
import io
import json
import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("ensure_tools", ROOT / "scripts/ensure-tools.py")
assert spec is not None and spec.loader is not None
installer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(installer)


class BootstrapTests(unittest.TestCase):
    def setUp(self) -> None:
        self.stack = contextlib.ExitStack()
        self.addCleanup(self.stack.close)
        tmp = self.stack.enter_context(tempfile.TemporaryDirectory())
        self.stack.enter_context(patch.object(installer, "BIN_DIR", Path(tmp)))
        self.stack.enter_context(patch.object(installer, "IS_MAC", False))
        self.stack.enter_context(patch.object(installer, "IS_LINUX", True))
        self.stack.enter_context(patch.object(installer, "is_installed", return_value="installed"))
        self.stack.enter_context(patch.object(installer, "ensure_symlink"))
        self.bootstraps = {
            name: self.stack.enter_context(patch.object(installer, name, return_value=True))
            for name in ("ensure_brew", "ensure_rust", "ensure_uv", "ensure_node")
        }
        # Fail the test if any unmocked installer tries to run a command or download.
        self.stack.enter_context(patch.object(subprocess, "run", side_effect=AssertionError("unexpected command")))
        self.stack.enter_context(patch.object(installer.urllib.request, "urlopen", side_effect=AssertionError("unexpected network")))
        self.stack.enter_context(patch.object(installer.urllib.request, "urlretrieve", side_effect=AssertionError("unexpected network")))
        self.output = self.stack.enter_context(contextlib.redirect_stderr(io.StringIO()))
        installer.update_apt_index.cache_clear()

    def test_complete_install(self) -> None:
        self.assertEqual(installer.main(), 0)
        self.assertIn("all tools installed!", self.output.getvalue())

    def test_bootstrap_failures_are_reported_and_remaining_steps_run(self) -> None:
        for name in ("ensure_rust", "ensure_uv", "ensure_node"):
            self.bootstraps[name].return_value = False
        self.assertEqual(installer.main(), 1)
        self.assertIn("failed to install: rust/cargo, uv, node/npm", self.output.getvalue())
        self.assertNotIn("all tools installed!", self.output.getvalue())
        for name in ("ensure_rust", "ensure_uv", "ensure_node"):
            self.bootstraps[name].assert_called_once()

    def test_low_memory_skips_are_not_failures(self) -> None:
        self.bootstraps["ensure_rust"].return_value = None
        self.bootstraps["ensure_node"].return_value = None
        self.assertEqual(installer.main(), 0)
        self.assertIn("skipped for low memory: rust/cargo, node/npm", self.output.getvalue())
        self.assertNotIn("all tools installed!", self.output.getvalue())

    def test_failed_homebrew_reports_uninstalled_cli_tools(self) -> None:
        self.bootstraps["ensure_brew"].return_value = False
        with patch.object(installer, "IS_MAC", True), patch.object(installer, "IS_LINUX", False), patch.object(installer, "has_brew", return_value=False):
            self.assertEqual(installer.main(), 1)
        self.assertIn("failed to install: homebrew, CLI tools", self.output.getvalue())

    def test_non_apt_linux_uses_download_fallback(self) -> None:
        with patch.object(installer, "has_apt", return_value=False), patch.object(installer, "is_installed", return_value=None), patch.object(installer, "install_from_github", return_value=True) as download:
            self.assertEqual(installer.main(), 0)
        self.assertEqual(download.call_count, len(installer.TOOLS))

    def test_github_only_install_does_not_update_apt(self) -> None:
        github_tools = [tool for tool in installer.TOOLS if tool["name"] == "nushell"]
        with patch.object(installer, "TOOLS", github_tools), patch.object(installer, "is_installed", return_value=None), patch.object(installer, "has_apt", return_value=True), patch.object(installer, "install_from_github", return_value=True):
            self.assertEqual(installer.main(), 0)

    def test_apt_updates_once_for_multiple_packages(self) -> None:
        with patch.object(installer, "has_apt", return_value=True), patch.object(installer, "run", return_value=subprocess.CompletedProcess([], 0)) as run:
            self.assertTrue(installer.install_via_apt(["bat"]))
            self.assertTrue(installer.install_via_apt(["fd-find"]))
        self.assertEqual([call.args[0] for call in run.call_args_list], [
            ["sudo", "apt-get", "update", "-qq"],
            ["sudo", "apt-get", "install", "-y", "bat"],
            ["sudo", "apt-get", "install", "-y", "fd-find"],
        ])

    def test_failed_apt_update_allows_download_fallback(self) -> None:
        with patch.object(installer, "has_apt", return_value=True), patch.object(installer, "is_installed", return_value=None), patch.object(installer, "run", return_value=subprocess.CompletedProcess([], 1)) as run, patch.object(installer, "install_from_github", return_value=True):
            self.assertEqual(installer.main(), 0)
        run.assert_called_once_with(["sudo", "apt-get", "update", "-qq"])

    def test_missing_command_returns_failure(self) -> None:
        with patch.object(subprocess, "run", side_effect=FileNotFoundError("sudo")):
            self.assertEqual(installer.run(["sudo", "apt-get", "update"]).returncode, 127)

    def test_failed_tool_does_not_stop_later_tools(self) -> None:
        with patch.object(installer, "has_apt", return_value=False), patch.object(installer, "is_installed", return_value=None), patch.object(installer, "install_from_github", side_effect=lambda repo, *_: repo != "sharkdp/bat") as download:
            self.assertEqual(installer.main(), 1)
        self.assertEqual(download.call_count, len(installer.TOOLS))
        self.assertIn("failed to install: bat", self.output.getvalue())


class ShellPathTests(unittest.TestCase):
    def test_shells_agree_on_path_and_editors(self) -> None:
        zsh = shutil.which("zsh")
        nu = shutil.which("nu")
        if zsh is None or nu is None:
            self.skipTest("zsh and nu are required for shell integration checks")
        assert zsh is not None and nu is not None
        zsh_block = self.mirrored_block("zsh/zshrc")
        nu_block = self.mirrored_block("nu/env.nu")
        env = {**os.environ, "PATH": "/usr/bin:/bin:/usr/bin"}
        for system in ("Linux", "Darwin"):
            with self.subTest(system=system), tempfile.TemporaryDirectory() as tmp:
                nu_script = Path(tmp) / "path.nu"
                nu_script.write_text(
                    f'def "sys host" [] {{ {{name: "{system}", long_os_version: "{system}"}} }}\n'
                    + nu_block + '\n[$env.PATH $env.EDITOR $env.VISUAL] | to json --raw\n'
                )
                nu_result = json.loads(subprocess.check_output([nu, "--no-config-file", str(nu_script)], env=env, text=True))
                zsh_script = f'uname() {{ echo {system}; }}\n' + zsh_block + '\nprintf "%s\\n" "$PATH" "$EDITOR" "$VISUAL"\n'
                zsh_result = subprocess.check_output([zsh, "-f", "-c", zsh_script], env=env, text=True).splitlines()
                self.assertEqual(nu_result, [zsh_result[0].split(":"), *zsh_result[1:]])
                self.assertEqual(len(nu_result[0]), len(set(nu_result[0])))
                home = str(Path.home())
                brew = "/opt/homebrew/bin" if system == "Darwin" else "/home/linuxbrew/.linuxbrew/bin"
                self.assertEqual(nu_result[0][:5], [f"{home}/.ddcoterm/bin", f"{home}/.ddcoterm/overrides", f"{home}/.volta/bin", f"{home}/bin", brew])

    @staticmethod
    def mirrored_block(path: str) -> str:
        text = (ROOT / path).read_text()
        return text.split("# ─── BEGIN mirrored block ───", 1)[1].split("# ─── END mirrored block ───", 1)[0]


if __name__ == "__main__":
    unittest.main()
