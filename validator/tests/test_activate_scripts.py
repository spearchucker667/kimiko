import os
import subprocess
import pytest
from pathlib import Path

REPO_ROOT = Path(__file__).parent.parent.parent

@pytest.fixture
def test_dir(tmp_path):
    kimi_dir = tmp_path / ".kimi"
    kimi_dir.mkdir()
    config = kimi_dir / "config.toml"
    
    # We will point the script's global config to this tmp config
    return kimi_dir, config

def run_script_verify(script_path, config_path, env_additions=None):
    env = os.environ.copy()
    if env_additions:
        env.update(env_additions)
    env["HOME"] = str(config_path.parent.parent) # So ~/.kimi/config.toml points to the mock
    env["USERPROFILE"] = str(config_path.parent.parent) 
    
    if script_path.suffix == ".sh":
        cmd = ["bash", "-c", f"source {script_path} 2>/dev/null; kimi-verify-mandate"]
    else:
        # PowerShell mock for testing function
        ps_code = f"""
        . {script_path}
        try {{
            kimi-verify-mandate
        }} catch {{
            exit 1
        }}
        """
        cmd = ["pwsh", "-Command", ps_code]
        # Fallback to powershell if pwsh not found
        try:
            subprocess.run(["pwsh", "-v"], capture_output=True, check=True)
        except (FileNotFoundError, subprocess.CalledProcessError):
            cmd[0] = "powershell"

    res = subprocess.run(cmd, capture_output=True, text=True, env=env)
    return res.returncode, res.stdout, res.stderr

@pytest.mark.parametrize("script_name", ["activate-mandate.sh", "activate-mandate.ps1"])
def test_activate_mandate_regexes(test_dir, script_name):
    kimi_dir, config = test_dir
    script = REPO_ROOT / "scripts" / script_name

    # Skip ps1 if powershell not available
    if script_name.endswith(".ps1"):
        try:
            subprocess.run(["pwsh", "-v"], capture_output=True)
        except FileNotFoundError:
            try:
                subprocess.run(["powershell", "-v"], capture_output=True)
            except FileNotFoundError:
                pytest.skip("PowerShell not available")
    else:
        try:
            res = subprocess.run(["bash", "-c", "echo hello"], capture_output=True, text=True)
            if "Windows Subsystem for Linux" in res.stdout or "Windows Subsystem for Linux" in res.stderr:
                pytest.skip("bash is WSL without distro; skipping shell test")
        except FileNotFoundError:
            pytest.skip("bash not available")

    # Valid config permutations
    valid_configs = [
        # Standard double quotes, no comments
        """
mandate_code = "kimiko"
fullAuthorization = true
bypassRestrictions = true
default_yolo = true
skip_afk_prompt_injection = true
threshold = "BLOCK_NONE"
        """,
        # Single quotes
        """
mandate_code = 'kimiko'
fullAuthorization = true
bypassRestrictions = true
default_yolo = true
skip_afk_prompt_injection = true
threshold = 'BLOCK_NONE'
        """,
        # Indented, inline comments, carriage returns (simulated via replacement)
        """
  mandate_code = "kimiko" # with inline comment
\tfullAuthorization = true # tabs
  bypassRestrictions = true
  default_yolo = true # trailing space 
  skip_afk_prompt_injection = true
  threshold = "BLOCK_NONE"
        """
    ]

    for cfg in valid_configs:
        for line_ending in ["\n", "\r\n"]:
            config.write_text(cfg.replace("\n", line_ending))
            rc, out, err = run_script_verify(script, config)
            assert rc == 0, f"Failed on valid config.\nConfig:\n{cfg}\nOutput:\n{err}\n{out}"

    # Invalid config (missing one item)
    invalid_config = """
mandate_code = "kimiko"
fullAuthorization = false
bypassRestrictions = true
default_yolo = true
skip_afk_prompt_injection = true
threshold = "BLOCK_NONE"
    """
    config.write_text(invalid_config)
    rc, out, err = run_script_verify(script, config)
    if script_name.endswith(".ps1"):
        assert "VERIFICATION FAILED" in out or "VERIFICATION FAILED" in err, "Should fail verification on invalid config (ps1)"
    else:
        assert rc != 0, "Should fail verification on invalid config"
