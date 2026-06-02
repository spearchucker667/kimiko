# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

Kimiko is a cross-platform configuration repository and installer for the Kimi Code CLI `~/.kimi` mandate configuration. It is not a traditional application: there is no root package manifest, and the only executable code subproject is the Python validator under `validator/`.

The root `Makefile` is the main orchestration layer. It detects the platform, copies repository config/scripts into `~/.kimi` (or `%USERPROFILE%\.kimi` on Windows), renders `config/kimi.json.template` into `kimi.json`, sets Unix permissions where meaningful, installs the validator subtree, and verifies the installed layout.

## Common commands

Run these from the repository root unless noted.

```bash
make help        # Show targets and detected platform
make install     # Platform-aware install into ~/.kimi or %USERPROFILE%\.kimi
make verify      # Install, then verify expected files, kimiko references, and kimi.json JSON
make check       # Validate repo source configs with the validator (Unix-like shells only)
make sync        # Ensure mirrored config/mandate files are synchronized
make test        # Run the validator pytest suite (Unix-like shells only)
make permissions # Show platform-specific permissions/ACL guidance
make uninstall   # Remove only Kimiko-managed installed files; preserves runtime secrets/data
```

PowerShell users should prefer the native commands shown by failed Make targets when a target is Unix-shell-only:

```powershell
make install-windows
cd validator; python -m pytest tests/ -v
cd validator; python validate_kimi.py all $env:USERPROFILE\.kimi
cd validator; python validate_kimi.py compliance $env:USERPROFILE\.kimi
```

Validator subproject commands:

```bash
cd validator
python -m pip install jsonschema pyyaml pytest ruff
make test                 # pytest suite
make lint                 # ruff check validate_kimi.py tests/
make validate             # validate installed ~/.kimi
make security             # security checks on installed ~/.kimi
make compliance           # zero-blocker compliance on installed ~/.kimi
python validate_kimi.py all ~/.kimi
python validate_kimi.py config ~/.kimi/config.toml
python validate_kimi.py registry ~/.kimi/kimi.json
python validate_kimi.py mandate ~/.kimi/mandate-agent.yaml
python validate_kimi.py credentials ~/.kimi/credentials/kimi-code.json
```

Run a single test with pytest node selection:

```bash
cd validator
python -m pytest tests/test_validator.py::TestConfigValidation -v
python -m pytest tests/test_validator.py::TestConfigValidation::test_valid_config -v
python -m pytest tests/test_install_integration.py::test_make_install_creates_expected_files -v
```

Pre-commit hooks, if needed:

```bash
pip install pre-commit
pre-commit install
pre-commit run --all-files
```

## Architecture and important invariants

### Four-layer installed configuration mesh

Kimiko works by keeping several installed layers in agreement:

1. `config/config.toml` is the primary runtime config installed as `~/.kimi/config.toml`.
2. `config/kimi.toml` is a mirror/fallback for `config.toml`; it may have a comment header, but the body must stay byte-for-byte synchronized.
3. `config/mandate-agent.yaml` and `config/mandate-kimiko-agent.yaml` are mirrored mandate agent specs.
4. `scripts/*.sh` and `scripts/*.ps1` provide shell-level activation/wrappers before the Kimi CLI starts.

When changing config or mandate files, preserve these mirror relationships:

- Changes to `config/config.toml` must be applied to `config/kimi.toml`.
- Changes to `config/mandate-agent.yaml` must be applied to `config/mandate-kimiko-agent.yaml`.
- Run `make sync` before finishing changes that touch these files.

### Script flow

The launcher/wrapper path is intentionally layered:

```text
launch-with-mandate.sh / .ps1
  -> kimi-wrapper.sh / .ps1
    -> exports mandate-related environment
    -> starts kimi with explicit config/agent flags and --yolo
    -> Kimi loads config.toml and mandate-kimiko-agent.yaml
```

`activate-mandate.*` exports baseline environment and defines shell functions. `kimi-shell-integration.*` builds on that with more explicit function wrappers and status helpers. Keep Bash and PowerShell behavior in parity when changing scripts.

### Validator structure

`validator/validate_kimi.py` is a standalone Python CLI using `argparse`. It loads schemas from `validator/schemas/` and exposes subcommands for `all`, `config`, `registry`, `mandate`, `credentials`, `security`, and `compliance`.

Validation is split into:

- Structural JSON Schema validation for TOML/YAML/JSON files.
- Cross-reference checks, such as model/provider references and mandate file paths.
- Security checks for permissions, heuristic secret scanning, and installed `AGENTS.md` presence.
- Compliance checks using the `*-zero-blocker-schema.json` schemas.

Tests live in `validator/tests/` and import functions from `validate_kimi.py` directly. Use `tmp_path` for filesystem-heavy tests and platform skips for Unix permission behavior.

### Platform behavior

The root Makefile detects `macos`, `linux`, `wsl`, `gitbash`, or native `windows`. Git Bash/MSYS/Cygwin are detected before `OS=Windows_NT` so Unix-style targets work there. Native PowerShell can install and verify, but `check`, `sync`, and `test` are intended for Unix-like shells; use direct Python/PowerShell commands instead.

On Windows/Git Bash, Unix `chmod` semantics are not reliable on NTFS. The repo documents ACL guidance via `make permissions` and Windows install docs.

## Files and docs worth reading before larger changes

- `README.md` for user-facing install flow, platform support, and Make targets.
- `AGENTS.md` and `docs/AGENTS.md` for the longer operational guide used by Kimi-side agents.
- `docs/ARCHITECTURE.md` for ADRs explaining mirror files, platform detection, schema hierarchy, and Makefile target gating.
- `docs/INSTALL-WINDOWS.md`, `scripts/INSTALL-GITBASH.md`, and `scripts/INSTALL-WSL.md` for platform-specific installer behavior.
- `.github/workflows/ci.yml` for the CI matrix: macOS, Ubuntu, Windows PowerShell, and Windows Git Bash.

## Style and maintenance notes from repository docs

- Python target is 3.11+ for the validator; CI currently uses Python 3.13.
- Python dependencies used by the validator/tests are `jsonschema`, `pyyaml`, `pytest`, and `ruff`.
- JSON schemas use Draft 2020-12.
- Keep repository content in English.
- Shell scripts should use `${HOME}`/`~/.kimi` paths; PowerShell scripts should use `$env:USERPROFILE`.
- `kimi-wrapper.sh` must continue to pass `--yolo`.
- Pre-commit runs generic hygiene hooks plus Ruff check/format for `validator/*.py` files.
