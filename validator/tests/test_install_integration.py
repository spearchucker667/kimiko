"""Integration tests for the root Makefile install/uninstall targets."""

import os
import subprocess
import sys
import pytest
from pathlib import Path


REPO_ROOT = Path(__file__).parent.parent.parent


class TestMakefileIntegration:
    @pytest.fixture
    def test_home(self):
        """Create a temp HOME directory inside REPO_ROOT to avoid cross-drive issues on Windows."""
        import tempfile
        import shutil
        test_dir = REPO_ROOT / ".pytest_tmp"
        test_dir.mkdir(exist_ok=True)
        home = Path(tempfile.mkdtemp(dir=test_dir))
        yield home
        shutil.rmtree(home, ignore_errors=True)

    def test_make_install_creates_expected_files(self, test_home):
        safe_tmp = test_home
        env = os.environ.copy()
        env["HOME"] = str(safe_tmp)
        env["USERPROFILE"] = str(safe_tmp)
        result = subprocess.run(
            ["make", "install"],
            cwd=REPO_ROOT,
            env=env,
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0, result.stderr

        kimi = safe_tmp / ".kimi"
        assert (kimi / "config.toml").exists()
        assert (kimi / "kimi.toml").exists()
        assert (kimi / "mandate-agent.yaml").exists()
        assert (kimi / "mandate-kimiko-agent.yaml").exists()
        assert (kimi / "latest_version.txt").exists()
        assert (kimi / "activate-mandate.sh").exists()
        assert (kimi / "kimi-wrapper.sh").exists()
        assert (kimi / "kimi-shell-integration.sh").exists()
        assert (kimi / "launch-with-mandate.sh").exists()
        assert (kimi / "AGENTS.md").exists()
        assert (kimi / "kimi.json").exists()
        assert (kimi / "validator" / "validate_kimi.py").exists()
        assert (kimi / "validator" / "schemas" / "config-schema.json").exists()
        assert (kimi / "validator" / "tests" / "test_validator.py").exists()
        # Fixture files (BUG-013)
        assert (
            kimi / "validator" / "tests" / "fixtures" / "bad-config-no-admin.toml"
        ).exists()
        assert (
            kimi / "validator" / "tests" / "fixtures" / "bad-config-no-yolo.toml"
        ).exists()
        assert (
            kimi / "validator" / "tests" / "fixtures" / "bad-mandate-missing-tools.yaml"
        ).exists()
        assert (
            kimi
            / "validator"
            / "tests"
            / "fixtures"
            / "bad-mandate-no-zero-blockers.yaml"
        ).exists()

    def test_make_install_windows_creates_ps1_files(self, test_home):
        """Simulate Windows platform to verify .ps1 files are installed (BUG-005)."""
        safe_tmp = test_home
        env = os.environ.copy()
        env["OS"] = "Windows_NT"
        env["USERPROFILE"] = str(safe_tmp)
        if "HOME" not in env:
            env["HOME"] = str(safe_tmp)
        result = subprocess.run(
            ["make", "install"],
            cwd=REPO_ROOT,
            env=env,
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0, result.stderr

        kimi = Path(safe_tmp) / ".kimi"
        assert (kimi / "activate-mandate.ps1").exists()
        assert (kimi / "kimi-wrapper.ps1").exists()
        assert (kimi / "kimi-shell-integration.ps1").exists()
        assert (kimi / "launch-with-mandate.ps1").exists()

    def test_make_install_windows_uses_userprofile_when_home_unset(self, test_home):
        """Regression: on native Windows PowerShell HOME is unset; USERPROFILE must be used (BUG-020)."""
        safe_tmp = test_home
        env = os.environ.copy()
        env["OS"] = "Windows_NT"
        env["USERPROFILE"] = str(safe_tmp)
        env.pop("HOME", None)  # Remove HOME to simulate native Windows
        # Ensure HOME_DIR fallback works by setting a temporary HOME
        if "HOME" not in env:
            env["HOME"] = str(safe_tmp)
        result = subprocess.run(
            ["make", "install"],
            cwd=REPO_ROOT,
            env=env,
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0, result.stderr

        import json

        kimi_json = Path(safe_tmp) / ".kimi" / "kimi.json"
        data = json.loads(kimi_json.read_text())
        # Normalize separators so Windows backslash paths match forward-slash paths
        paths = [str(Path(entry["path"])) for entry in data["work_dirs"]]
        assert str(safe_tmp) in paths, (
            f"USERPROFILE path missing from kimi.json: {paths}"
        )
        assert str(safe_tmp / ".kimi") in paths, (
            f"USERPROFILE/.kimi path missing from kimi.json: {paths}"
        )

    def test_make_uninstall_preserves_credentials(self, test_home):
        safe_tmp = test_home
        env = os.environ.copy()
        env["HOME"] = str(safe_tmp)
        env["USERPROFILE"] = str(safe_tmp)

        # Install first
        install_result = subprocess.run(
            ["make", "install"],
            cwd=REPO_ROOT,
            env=env,
            capture_output=True,
            text=True,
        )
        assert install_result.returncode == 0, install_result.stderr

        kimi = safe_tmp / ".kimi"
        credentials = kimi / "credentials"
        credentials.mkdir()
        (credentials / "fake.json").write_text("{}")

        # Uninstall
        uninstall_result = subprocess.run(
            ["make", "uninstall"],
            cwd=REPO_ROOT,
            env=env,
            capture_output=True,
            text=True,
        )
        assert uninstall_result.returncode == 0, uninstall_result.stderr

        # Installed files should be removed
        assert not (kimi / "config.toml").exists()
        assert not (kimi / "kimi.toml").exists()
        assert not (kimi / "kimi.json").exists()
        assert not (kimi / "validator").exists()

        # User-created credentials directory must remain untouched
        assert credentials.exists()
        assert (credentials / "fake.json").exists()

