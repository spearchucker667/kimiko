"""Tests for activate-mandate.sh and activate-mandate.ps1 regex logic.

These tests verify that the mandate verification regexes correctly handle
TOML edge cases: single/double quotes, inline comments, indentation, and
CRLF line endings.

On Windows CI, the .sh test is skipped because the Git Bash runner's PATH
often resolves to WSL's bash.exe (which has no distro) rather than Git Bash's
bash.exe.  The .sh logic is fully exercised on macOS and Ubuntu runners.
"""

import os
import subprocess
import sys
import pytest
from pathlib import Path

REPO_ROOT = Path(__file__).parent.parent.parent


@pytest.fixture
def test_dir(tmp_path):
    kimi_dir = tmp_path / ".kimi"
    kimi_dir.mkdir()
    config = kimi_dir / "config.toml"
    return kimi_dir, config


def _find_powershell():
    """Return the powershell executable name, or None if unavailable."""
    for name in ("pwsh", "powershell"):
        try:
            subprocess.run([name, "-Version"], capture_output=True, check=True)
            return name
        except (FileNotFoundError, subprocess.CalledProcessError):
            continue
    return None


def run_script_verify(script_path, config_path, ps_exe=None):
    env = os.environ.copy()
    env["HOME"] = str(config_path.parent.parent)
    env["USERPROFILE"] = str(config_path.parent.parent)

    if script_path.suffix == ".sh":
        cmd = ["bash", "-c", f"source {script_path} 2>/dev/null; kimi-verify-mandate"]
    else:
        ps_code = (
            f". '{script_path}'\n"
            "try { kimi-verify-mandate } catch { exit 1 }"
        )
        cmd = [ps_exe or "pwsh", "-NoProfile", "-Command", ps_code]

    res = subprocess.run(cmd, capture_output=True, text=True, env=env)
    return res.returncode, res.stdout, res.stderr


# ── Valid config permutations ────────────────────────────────────────────────
VALID_CONFIGS = [
    # Standard double quotes, no comments
    """\
mandate_code = "kimiko"
fullAuthorization = true
bypassRestrictions = true
default_yolo = true
skip_afk_prompt_injection = true
threshold = "BLOCK_NONE"
""",
    # Single quotes
    """\
mandate_code = 'kimiko'
fullAuthorization = true
bypassRestrictions = true
default_yolo = true
skip_afk_prompt_injection = true
threshold = 'BLOCK_NONE'
""",
    # Indented with inline comments
    """\
  mandate_code = "kimiko" # with inline comment
\tfullAuthorization = true # tabs
  bypassRestrictions = true
  default_yolo = true # trailing space
  skip_afk_prompt_injection = true
  threshold = "BLOCK_NONE"
""",
]

INVALID_CONFIG = """\
mandate_code = "kimiko"
fullAuthorization = false
bypassRestrictions = true
default_yolo = true
skip_afk_prompt_injection = true
threshold = "BLOCK_NONE"
"""


# ── Bash tests — skip on Windows ─────────────────────────────────────────────
@pytest.mark.skipif(sys.platform == "win32", reason="bash tests run on macOS/Linux CI")
class TestActivateMandateSh:
    def test_valid_configs(self, test_dir):
        _, config = test_dir
        script = REPO_ROOT / "scripts" / "activate-mandate.sh"
        for cfg in VALID_CONFIGS:
            for line_ending in ["\n", "\r\n"]:
                config.write_text(cfg.replace("\n", line_ending))
                rc, out, err = run_script_verify(script, config)
                assert rc == 0, f"Failed on valid config.\nConfig:\n{cfg}\nstderr:\n{err}\nstdout:\n{out}"

    def test_invalid_config_fails(self, test_dir):
        _, config = test_dir
        script = REPO_ROOT / "scripts" / "activate-mandate.sh"
        config.write_text(INVALID_CONFIG)
        rc, out, err = run_script_verify(script, config)
        assert rc != 0, "Should fail verification on invalid config"


# ── PowerShell tests — skip if pwsh/powershell unavailable ───────────────────
class TestActivateMandatePs1:
    @pytest.fixture(autouse=True)
    def _require_powershell(self):
        ps = _find_powershell()
        if ps is None:
            pytest.skip("PowerShell not available")
        self._ps_exe = ps

    def test_valid_configs(self, test_dir):
        _, config = test_dir
        script = REPO_ROOT / "scripts" / "activate-mandate.ps1"
        for cfg in VALID_CONFIGS:
            for line_ending in ["\n", "\r\n"]:
                config.write_text(cfg.replace("\n", line_ending))
                rc, out, err = run_script_verify(script, config, ps_exe=self._ps_exe)
                assert rc == 0, f"Failed on valid config.\nConfig:\n{cfg}\nstderr:\n{err}\nstdout:\n{out}"

    def test_invalid_config_fails(self, test_dir):
        _, config = test_dir
        script = REPO_ROOT / "scripts" / "activate-mandate.ps1"
        config.write_text(INVALID_CONFIG)
        rc, out, err = run_script_verify(script, config, ps_exe=self._ps_exe)
        assert "VERIFICATION FAILED" in out or "VERIFICATION FAILED" in err, \
            "Should fail verification on invalid config (ps1)"
