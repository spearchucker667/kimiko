# Kimiko

A public-ready, sanitized macOS configuration repository that reproduces the zero-blocker mandate behavior for the [Kimi Code CLI](https://www.moonshot.cn/).

When you enter **`kimiko`** in a Kimi CLI session, the full authorization/config flow activates—exactly like the original private `~/.kimi` setup, but without any personal credentials, session data, or machine-specific secrets.

---

## What This Project Does

Kimiko packages the shared, reproducible parts of a `~/.kimi` directory into a single Makefile-driven installer. After installation:

- Your local `~/.kimi/` contains the hardened **config.toml**, **kimi.toml**, mandate agent specs, shell integration scripts, and the built-in **validator** tool.
- Launching `kimi` via the wrapper or shell integration loads the mandate automatically.
- Typing **`kimiko`** inside a Kimi CLI session triggers the authorization flow and capability announcement.

**Nothing personal is included.** There are no OAuth tokens, device IDs, session histories, logs, or backups in this repo.

---

## Prerequisites

- **macOS** (Darwin/BSD tools)
- **Kimi Code CLI** installed and available at `~/.local/bin/kimi` (or in your `PATH`)
- **make** (macOS ships with BSD make)
- **Python 3.11+** (only if you want to run the validator tests/schemas)

---

## Quick Start

```bash
# 1. Clone the repo
git clone https://github.com/spearchucker667/kimiko.git
cd kimiko

# 2. Run the installer
make install

# 3. Source the mandate activation (or add to ~/.zshrc / ~/.bashrc)
source ~/.kimi/activate-mandate.sh

# 4. Launch Kimi with the mandate wrapper
~/.kimi/launch-with-mandate.sh

# 5. Inside the CLI, enter the activation word
kimiko
```

After step 5 you should see the mandate acknowledgment and capability announcement identical to the original configuration.

> **Tip:** For a deep-dive into the mandate architecture, configuration layers, and troubleshooting, see [`AGENTS.md`](./AGENTS.md).

---

## Makefile Targets

| Target | Description |
|---|---|
| `make install` | Idempotently copies all shared configs, scripts, and the validator into `~/.kimi/`. Renders `kimi.json` from its template. |
| `make verify` | Checks that all expected files exist, the validator directory is present, and `kimiko` references are intact. |
| `make uninstall` | Removes only the files installed by Kimiko. **Does not touch** `credentials/`, `logs/`, `sessions/`, `telemetry/`, `user-history/`, or any other user secrets. |
| `make help` | Shows available targets. |

---

## Directory Structure Created

```
~/.kimi/
├── AGENTS.md
├── activate-mandate.sh
├── config.toml
├── kimi-shell-integration.sh
├── kimi-wrapper.sh
├── kimi.json          ← rendered from template
├── kimi.toml
├── launch-with-mandate.sh
├── latest_version.txt
├── mandate-agent.yaml
├── mandate-kimiko-agent.yaml
└── validator/
    ├── Makefile
    ├── README.md
    ├── validate_kimi.py
    ├── schemas/
    │   ├── config-schema.json
    │   ├── config-zero-blocker-schema.json
    │   ├── credentials-schema.json
    │   ├── kimi-json-schema.json
    │   ├── mandate-schema.json
    │   └── mandate-zero-blocker-schema.json
    └── tests/
        └── test_validator.py
```

---

## Security & Privacy Notes

- **No credentials are included.** You must authenticate the Kimi CLI yourself via its normal OAuth flow.
- `kimi.json` is generated from a template during `make install`; it contains only placeholder paths for your own home directory.
- If you previously had a `~/.kimi/credentials/` directory, `make uninstall` will **not** remove it.
- The shell scripts use `${HOME}` everywhere so they work on any macOS user account.

---

## Validator

The included `validator/` tool can sanity-check your `~/.kimi` installation:

```bash
cd ~/.kimi/validator
make validate        # Full validation
make test            # pytest suite
make validate-config # config.toml only
make validate-mandates # mandate YAML files
make security        # Security checks only
make lint            # Python linter (ruff)
```

---

## Customization

Before running `make install`, you may want to edit these placeholders in the copied files:

- `config.toml` and `kimi.toml`: replace `<YOUR_USERNAME>` and `<YOUR_PERSONA_UUID>` under `[system_status.kimi_ai_persona]`.
- `kimi.json.template`: the Makefile automatically substitutes `<YOUR_HOME_DIR>` with your actual `$HOME`.

---

## License

See [LICENSE](./LICENSE).
