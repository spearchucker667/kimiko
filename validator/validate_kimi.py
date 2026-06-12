#!/usr/bin/env python3
"""
Kimi CLI Configuration Validator v1.0.0

Validates .kimi directory configuration files for structural integrity,
security posture, cross-reference consistency, and mandate compliance.

Usage:
    python validate_kimi.py all [~/.kimi-code]
    python validate_kimi.py config <config.toml>
    python validate_kimi.py registry <kimi.json>
    python validate_kimi.py mandate <mandate-agent.yaml>
    python validate_kimi.py credentials <kimi-code.json>
    python validate_kimi.py security [~/.kimi-code]

Exit codes:
    0 - All validations passed
    1 - Validation errors found
    2 - Usage / argument error
"""

import argparse
import json
import platform
import re
import stat
import sys
import uuid
from pathlib import Path
from typing import Any

# External dependencies — fail fast with clear messages if missing
try:
    import yaml
except ImportError as e:
    raise ImportError("PyYAML is required: pip install pyyaml") from e

try:
    from jsonschema import Draft202012Validator, ValidationError, FormatChecker
except ImportError as e:
    raise ImportError("jsonschema is required: pip install jsonschema") from e

try:
    import tomllib
except ImportError:
    try:
        import tomli as tomllib
    except ImportError as e:
        raise ImportError(
            "TOML parsing requires Python 3.11+ or `pip install tomli`"
        ) from e


# ── ANSI Colors ──────────────────────────────────────────────────────────────
class C:
    R = "\033[91m"
    G = "\033[92m"
    Y = "\033[93m"
    B = "\033[94m"
    C = "\033[96m"
    RST = "\033[0m"
    BLD = "\033[1m"

try:
    "✓✗⚠".encode(sys.stdout.encoding or "utf-8")
    SYM_OK, SYM_ERR, SYM_WARN = "✓", "✗", "⚠"
except UnicodeEncodeError:
    SYM_OK, SYM_ERR, SYM_WARN = "OK", "ERR", "WARN"


def colorize(text: str, color: str, stream: Any = sys.stdout) -> str:
    if stream.isatty():
        return f"{color}{text}{C.RST}"
    return text


# ── Schema Loading ───────────────────────────────────────────────────────────
SCHEMA_DIR = Path(__file__).parent / "schemas"


def load_schema(name: str) -> dict[str, Any]:
    path = SCHEMA_DIR / name
    if not path.exists():
        raise FileNotFoundError(f"Schema not found: {path}")
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


# ── File Loaders ─────────────────────────────────────────────────────────────
def load_toml(path: Path) -> dict[str, Any]:
    with open(path, "rb") as f:
        return tomllib.load(f)


def load_yaml(path: Path) -> Any:
    with open(path, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)


def load_json(path: Path) -> Any:
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


# ── Validation Helpers ───────────────────────────────────────────────────────
def validate_against_schema(
    data: Any, schema: dict[str, Any], label: str
) -> tuple[bool, list[ValidationError]]:
    validator = Draft202012Validator(schema, format_checker=FormatChecker())
    errors = list(validator.iter_errors(data))
    return len(errors) == 0, errors


def print_errors(errors: list[ValidationError], verbose: bool = False) -> None:
    display = errors if verbose else errors[:10]
    for e in display:
        path = "/".join(str(p) for p in e.absolute_path) or "(root)"
        print(f"  {colorize(SYM_ERR, C.R)} {colorize(path, C.C)}: {e.message}")
    if not verbose and len(errors) > 10:
        print(f"  ... and {len(errors) - 10} more")


# ── Security Checks ──────────────────────────────────────────────────────────
def check_file_permissions(path: Path, expected_mode: int = 0o600) -> list[str]:
    """Ensure sensitive files are not world-readable.

    On Windows, this check is skipped because NTFS uses ACLs rather than
    Unix permission bits. Use Windows Explorer or icacls to verify ACLs.
    """
    errors: list[str] = []
    if platform.system().startswith(("Windows", "CYGWIN", "MSYS")):
        # NTFS ACLs are not reflected in st_mode; skip Unix permission check
        return errors
    try:
        st = path.stat()
        mode = stat.S_IMODE(st.st_mode)
        if mode & 0o077:
            errors.append(
                f"{path}: permissions {oct(mode)} are too permissive "
                f"(expected {oct(expected_mode)})"
            )
    except OSError as e:
        errors.append(f"{path}: cannot stat: {e}")
    return errors


def scan_for_secrets(text: str, path: Path) -> list[str]:
    """Heuristic scan for potential secret leaks in non-credential files."""
    findings: list[str] = []
    # Patterns to flag
    patterns = [
        (r"sk-[a-zA-Z0-9_-]{20,}", "API key pattern"),
        (
            r"eyJ[a-zA-Z0-9_/+-]*={0,2}\.eyJ[a-zA-Z0-9_/+-]*={0,2}\.[a-zA-Z0-9_/+-]*={0,2}",
            "JWT-like token",
        ),
        (r"password\s*=\s*[^\s]+", "hardcoded password"),
        (r"token\s*=\s*[^\s]+", "hardcoded token"),
    ]
    secret_context = re.compile(
        r"api_key|apikey|secret|token|password|private_key", re.IGNORECASE
    )
    lines = text.splitlines()
    for lineno, line in enumerate(lines, 1):
        # Hex patterns require surrounding context to avoid flagging git SHAs
        if re.search(r"[a-fA-F0-9]{40}", line):
            if secret_context.search(line):
                findings.append(
                    f"{path}:{lineno}: potential secret leak (hex secret-like pattern)"
                )
                continue

        for pattern, desc in patterns:
            if re.search(pattern, line, re.IGNORECASE):
                findings.append(f"{path}:{lineno}: potential secret leak ({desc})")
                break  # one finding per line is enough
    return findings


# ── Cross-Reference Validation ───────────────────────────────────────────────
def validate_config_crossrefs(data: dict[str, Any], base_path: Path) -> list[str]:
    """Validate that config.toml internal references are consistent."""
    errors: list[str] = []

    # 1. default_model must exist in [models]
    default_model = data.get("default_model")
    models = data.get("models", {})
    if default_model and default_model not in models:
        errors.append(f"default_model '{default_model}' not found in [models] table")

    # 2. Every model's provider must exist in [providers]
    providers = data.get("providers", {})
    for model_name, model_cfg in models.items():
        provider = model_cfg.get("provider")
        if provider and provider not in providers:
            errors.append(
                f"model '{model_name}' references unknown provider '{provider}'"
            )

    # 3. OAuth credential paths should exist (warn only; app may resolve differently)
    for provider_name, provider_cfg in providers.items():
        oauth = provider_cfg.get("oauth")
        if oauth and oauth.get("storage") == "file":
            key = oauth.get("key", "")
            # Resolve relative to ~/.kimi-code; also check credentials/ as fallback
            cred_path = base_path.parent / key
            alt_path = base_path.parent / "credentials" / (key.split("/")[-1] + ".json")
            if not cred_path.exists() and not alt_path.exists():
                errors.append(
                    f"provider '{provider_name}' oauth file missing: {cred_path} "
                    f"(also checked {alt_path})"
                )

    # 4. hooks paths should exist (if they are dicts, check the command or script if applicable, but for now we skip or check dict contents)
    for hook in data.get("hooks", []):
        if isinstance(hook, dict):
            # No specific path to validate if it's a dict representing hook config
            continue
        hook_path = Path(hook)
        if not hook_path.is_absolute():
            hook_path = base_path.parent / hook_path
        if not hook_path.exists():
            errors.append(f"hook path missing: {hook_path}")

    return errors


def validate_registry_paths(data: dict[str, Any]) -> list[str]:
    """Validate that kimi.json work_dirs paths exist."""
    errors: list[str] = []
    for entry in data.get("work_dirs", []):
        path = entry.get("path")
        if path and not Path(path).exists():
            errors.append(f"work_dirs path does not exist: {path}")
        session_id = entry.get("last_session_id")
        if session_id is not None:
            try:
                uuid.UUID(session_id)
            except ValueError:
                errors.append(f"invalid UUID in last_session_id: {session_id}")
    return errors


def validate_mandate_paths(data: dict[str, Any], base_path: Path) -> list[str]:
    """Validate that mandate file references exist."""
    errors: list[str] = []
    agent = data.get("agent", {})
    spp = agent.get("system_prompt_path")
    if spp:
        p = Path(spp)
        if not p.is_absolute():
            p = base_path.parent / p
        if not p.exists():
            errors.append(f"system_prompt_path missing: {p}")
    gc = agent.get("global_config", {})
    cf = gc.get("config_file")
    if cf:
        p = Path(cf)
        if not p.is_absolute():
            p = base_path.parent / p
        if not p.exists():
            errors.append(f"global_config.config_file missing: {p}")
    return errors


def cmd_compliance(args: argparse.Namespace) -> int:
    """Validate zero-blocker compliance using Mandate kimiko strict schemas."""
    base = Path(args.directory) if args.directory else Path.home() / ".kimi-code"
    if not base.is_dir():
        print(f"{colorize(SYM_ERR, C.R)} Not a directory: {base}")
        return 1

    overall = 0

    # Config compliance
    config_path = base / "config.toml"
    if config_path.exists():
        try:
            data = load_toml(config_path)
        except Exception as e:
            print(f"{colorize(SYM_ERR, C.R)} {config_path}: parse error: {e}")
            overall = max(overall, 1)
        else:
            schema = load_schema("config-zero-blocker-schema.json")
            valid, errors = validate_against_schema(data, schema, str(config_path))
            if valid:
                print(f"{colorize(SYM_OK, C.G)} {config_path}: Zero-blocker compliant")
            else:
                print(
                    f"{colorize(SYM_ERR, C.R)} {config_path}: Zero-blocker violations found"
                )
                print_errors(errors, args.verbose)
                overall = max(overall, 1)

    # kimi.toml compliance
    kimi_toml = base / "kimi.toml"
    if kimi_toml.exists():
        try:
            data = load_toml(kimi_toml)
        except Exception as e:
            print(f"{colorize(SYM_ERR, C.R)} {kimi_toml}: parse error: {e}")
            overall = max(overall, 1)
        else:
            schema = load_schema("config-zero-blocker-schema.json")
            valid, errors = validate_against_schema(data, schema, str(kimi_toml))
            if valid:
                print(f"{colorize(SYM_OK, C.G)} {kimi_toml}: Zero-blocker compliant")
            else:
                print(
                    f"{colorize(SYM_ERR, C.R)} {kimi_toml}: Zero-blocker violations found"
                )
                print_errors(errors, args.verbose)
                overall = max(overall, 1)

    # Mandate YAML compliance
    for mandate in ["mandate-agent.yaml", "mandate-kimiko-agent.yaml"]:
        mp = base / mandate
        if mp.exists():
            try:
                data = load_yaml(mp)
            except Exception as e:
                print(f"{colorize(SYM_ERR, C.R)} {mp}: parse error: {e}")
                overall = max(overall, 1)
            else:
                schema = load_schema("mandate-zero-blocker-schema.json")
                valid, errors = validate_against_schema(data, schema, str(mp))
                if valid:
                    print(f"{colorize(SYM_OK, C.G)} {mp}: Zero-blocker compliant")
                else:
                    print(f"{colorize(SYM_ERR, C.R)} {mp}: Zero-blocker violations found")
                    print_errors(errors, args.verbose)
                    overall = max(overall, 1)

    return overall


# ── Command Handlers ─────────────────────────────────────────────────────────
def cmd_config(args: argparse.Namespace) -> int:
    path = Path(args.file)
    try:
        data = load_toml(path)
    except Exception as e:
        print(f"{colorize(SYM_ERR, C.R)} {path}: parse error: {e}")
        return 1

    schema = load_schema("config-schema.json")
    valid, errors = validate_against_schema(data, schema, str(path))
    xerrs = (
        validate_config_crossrefs(data, path)
        if not getattr(args, "no_crossrefs", False)
        else []
    )

    if valid and not xerrs:
        print(f"{colorize(SYM_OK, C.G)} {path}: Valid")
        return 0

    print(f"{colorize(SYM_ERR, C.R)} {path}: Invalid")
    if errors:
        print(f"  Schema errors ({len(errors)}):")
        print_errors(errors, args.verbose)
    if xerrs:
        print(f"  Cross-reference errors ({len(xerrs)}):")
        for e in xerrs:
            print(f"  {colorize(SYM_ERR, C.R)} {e}")
    return 1


def cmd_registry(args: argparse.Namespace) -> int:
    path = Path(args.file)
    try:
        data = load_json(path)
    except Exception as e:
        print(f"{colorize(SYM_ERR, C.R)} {path}: parse error: {e}")
        return 1

    schema = load_schema("kimi-json-schema.json")
    valid, errors = validate_against_schema(data, schema, str(path))
    xerrs = validate_registry_paths(data)

    if valid and not xerrs:
        print(f"{colorize(SYM_OK, C.G)} {path}: Valid")
        return 0

    print(f"{colorize(SYM_ERR, C.R)} {path}: Invalid")
    if errors:
        print_errors(errors, args.verbose)
    if xerrs:
        for e in xerrs:
            print(f"  {colorize(SYM_ERR, C.R)} {e}")
    return 1


def cmd_mandate(args: argparse.Namespace) -> int:
    path = Path(args.file)
    try:
        data = load_yaml(path)
    except Exception as e:
        print(f"{colorize(SYM_ERR, C.R)} {path}: parse error: {e}")
        return 1

    schema = load_schema("mandate-schema.json")
    valid, errors = validate_against_schema(data, schema, str(path))
    xerrs = validate_mandate_paths(data, path)

    if valid and not xerrs:
        print(f"{colorize(SYM_OK, C.G)} {path}: Valid")
        return 0

    print(f"{colorize(SYM_ERR, C.R)} {path}: Invalid")
    if errors:
        print_errors(errors, args.verbose)
    if xerrs:
        for e in xerrs:
            print(f"  {colorize(SYM_ERR, C.R)} {e}")
    return 1


def cmd_credentials(args: argparse.Namespace) -> int:
    path = Path(args.file)
    try:
        data = load_json(path)
    except Exception as e:
        print(f"{colorize(SYM_ERR, C.R)} {path}: parse error: {e}")
        return 1

    schema = load_schema("credentials-schema.json")
    valid, errors = validate_against_schema(data, schema, str(path))
    perm_errs = check_file_permissions(path)

    if valid and not perm_errs:
        print(f"{colorize(SYM_OK, C.G)} {path}: Valid (permissions OK)")
        return 0

    print(f"{colorize(SYM_ERR, C.R)} {path}: Invalid")
    if errors:
        print_errors(errors, args.verbose)
    if perm_errs:
        for e in perm_errs:
            print(f"  {colorize(SYM_WARN, C.Y)} {e}")
    return 1


SECURITY_SIZE_LIMIT = 1_048_576


def cmd_security(args: argparse.Namespace) -> int:
    base = Path(args.directory) if args.directory else Path.home() / ".kimi-code"
    if not base.is_dir():
        print(f"{colorize(SYM_ERR, C.R)} Not a directory: {base}")
        return 1

    findings: list[str] = []
    skipped: list[str] = []

    # 1. Credential file permissions
    creds_dir = base / "credentials"
    if creds_dir.is_dir():
        for f in creds_dir.iterdir():
            if f.is_file():
                findings.extend(check_file_permissions(f))

    # 2. No secrets in non-credential files
    MAX_SCAN_DEPTH = 5
    for f in base.rglob("*"):
        if not f.is_file():
            continue
        depth = len(f.relative_to(base).parts) - 1
        if depth > MAX_SCAN_DEPTH:
            continue
        if f.name.startswith("."):
            continue
        # Skip common binary and backup / temp file suffixes
        if any(f.name.lower().endswith(suffix) for suffix in (
            "~", ".bak", ".tmp", ".swp", ".png", ".jpg", ".jpeg", ".gif", 
            ".ico", ".pdf", ".zip", ".tar", ".gz", ".lock"
        )):
            continue
        if "credential" in str(f).lower():
            continue
        if f.stat().st_size > SECURITY_SIZE_LIMIT:
            skipped.append(f"{f.name}: skipped (>{SECURITY_SIZE_LIMIT} bytes)")
            continue
        try:
            text = f.read_text(encoding="utf-8", errors="replace")
            findings.extend(scan_for_secrets(text, f))
        except Exception as exc:
            findings.append(f"{f.name}: could not read ({exc})")

    # 3. AGENTS.md presence
    if not (base / "AGENTS.md").exists():
        findings.append("AGENTS.md missing from .kimi root")

    # 4. Device ID file permissions
    device_id = base / "device_id"
    if device_id.exists():
        findings.extend(check_file_permissions(device_id))

    if not findings:
        print(f"{colorize(SYM_OK, C.G)} Security checks passed for {base}")
        if skipped:
            for s in skipped:
                print(f"  (info) {s}")
        return 0

    print(f"{colorize(SYM_WARN, C.Y)} Security findings in {base}:")
    for f in findings:
        print(f"  {colorize(SYM_WARN, C.Y)} {f}")
    if skipped:
        for s in skipped:
            print(f"  (info) {s}")
    return 1


def _sub_args(args: argparse.Namespace, **overrides: Any) -> argparse.Namespace:
    """Shallow copy of args with optional overrides."""
    ns = argparse.Namespace(**vars(args))
    # Plain test stubs (type() instances) store attributes as class attrs,
    # so vars() only returns instance attrs. Copy any missing public attrs.
    for attr in dir(args):
        if attr.startswith("_"):
            continue
        if not hasattr(ns, attr):
            setattr(ns, attr, getattr(args, attr))
    for k, v in overrides.items():
        setattr(ns, k, v)
    return ns


def cmd_all(args: argparse.Namespace) -> int:
    base = Path(args.directory) if args.directory else Path.home() / ".kimi-code"
    if not base.is_dir():
        print(f"{colorize(SYM_ERR, C.R)} Not a directory: {base}")
        return 1

    results: list[tuple[Path, bool, str]] = []
    overall = 0

    # Config
    config_path = base / "config.toml"
    if config_path.exists():
        rc = cmd_config(_sub_args(args, file=str(config_path)))
        results.append((config_path, rc == 0, "config"))
        overall = max(overall, rc)

    # kimi.toml (secondary)
    kimi_toml = base / "kimi.toml"
    if kimi_toml.exists():
        rc = cmd_config(_sub_args(args, file=str(kimi_toml)))
        results.append((kimi_toml, rc == 0, "kimi.toml"))
        overall = max(overall, rc)

    # Registry
    registry_path = base / "kimi.json"
    if registry_path.exists():
        rc = cmd_registry(_sub_args(args, file=str(registry_path)))
        results.append((registry_path, rc == 0, "registry"))
        overall = max(overall, rc)

    # Mandates
    for mandate in ["mandate-agent.yaml", "mandate-kimiko-agent.yaml"]:
        mp = base / mandate
        if mp.exists():
            rc = cmd_mandate(_sub_args(args, file=str(mp)))
            results.append((mp, rc == 0, "mandate"))
            overall = max(overall, rc)

    # Credentials
    creds_dir = base / "credentials"
    if creds_dir.is_dir():
        for cf in creds_dir.glob("*.json"):
            if cf.name.endswith(".lock"):
                continue
            rc = cmd_credentials(_sub_args(args, file=str(cf)))
            results.append((cf, rc == 0, "credentials"))
            overall = max(overall, rc)

    # Security sweep
    rc = cmd_security(_sub_args(args, directory=str(base)))
    results.append((base, rc == 0, "security"))
    overall = max(overall, rc)

    # Summary
    print(f"\n{colorize('Summary', C.BLD)}")
    print("=" * 50)
    for p, ok, kind in results:
        status = colorize("PASS", C.G) if ok else colorize("FAIL", C.R)
        print(f"  {status}  [{kind:12s}]  {p.name}")
    print("=" * 50)
    return overall


# ── Main ─────────────────────────────────────────────────────────────────────
def main() -> int:
    parser = argparse.ArgumentParser(
        description="Kimi CLI Configuration Validator v1.0.0",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s all ~/.kimi-code
  %(prog)s config ~/.kimi-code/config.toml
  %(prog)s registry ~/.kimi-code/kimi.json
  %(prog)s mandate ~/.kimi-code/mandate-agent.yaml
  %(prog)s credentials ~/.kimi-code/credentials/kimi-code.json
  %(prog)s security ~/.kimi-code
  %(prog)s compliance ~/.kimi-code
        """,
    )
    parser.add_argument(
        "--verbose", "-v", action="store_true", help="Show all validation errors"
    )

    sub = parser.add_subparsers(dest="command", help="Validation target")

    p_all = sub.add_parser("all", help="Validate entire .kimi directory")
    p_all.add_argument("directory", nargs="?", help="Path to .kimi directory")

    p_cfg = sub.add_parser("config", help="Validate a config.toml file")
    p_cfg.add_argument("file", help="Path to config.toml")
    p_cfg.add_argument(
        "--no-crossrefs", action="store_true", help="Skip cross-reference validation"
    )

    p_reg = sub.add_parser("registry", help="Validate a kimi.json file")
    p_reg.add_argument("file", help="Path to kimi.json")

    p_man = sub.add_parser("mandate", help="Validate a mandate YAML file")
    p_man.add_argument("file", help="Path to mandate-agent.yaml")

    p_cred = sub.add_parser("credentials", help="Validate a credentials JSON file")
    p_cred.add_argument("file", help="Path to credentials JSON")

    p_sec = sub.add_parser("security", help="Run security checks on .kimi directory")
    p_sec.add_argument("directory", nargs="?", help="Path to .kimi directory")

    p_comp = sub.add_parser(
        "compliance", help="Validate zero-blocker Mandate kimiko compliance"
    )
    p_comp.add_argument("directory", nargs="?", help="Path to .kimi directory")

    args = parser.parse_args()

    if args.command is None:
        parser.print_help()
        return 2

    cmds = {
        "all": cmd_all,
        "config": cmd_config,
        "registry": cmd_registry,
        "mandate": cmd_mandate,
        "credentials": cmd_credentials,
        "security": cmd_security,
        "compliance": cmd_compliance,
    }
    return cmds[args.command](args)


if __name__ == "__main__":
    sys.exit(main())
