# Kimiko

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
![macOS](https://img.shields.io/badge/macOS-only-000000?logo=apple)
![Python](https://img.shields.io/badge/Python-3.11+-3776AB?logo=python)

A public-ready, sanitized macOS configuration repository that reproduces the zero-blocker mandate behavior for the [Kimi Code CLI](https://www.moonshot.cn/).

When you enter **`kimiko`** in a Kimi CLI session, the full authorization/config flow activates.

## Quick Start

```bash
git clone https://github.com/spearchucker667/kimiko.git
cd kimiko
make install
source ~/.kimi/activate-mandate.sh
~/.kimi/launch-with-mandate.sh
```

## Documentation

- **[docs/README.md](docs/README.md)** — Full quick-start, directory structure, and customization guide
- **[docs/AGENTS.md](docs/AGENTS.md)** — Deep-dive into mandate architecture, compliance, and troubleshooting
- **[docs/CHANGELOG.md](docs/CHANGELOG.md)** — Version history
- **[docs/CONTRIBUTING.md](docs/CONTRIBUTING.md)** — Contribution guidelines
- **[docs/SECURITY.md](docs/SECURITY.md)** — Security disclosure policy
- **[docs/legal/DISCLAIMER.md](docs/legal/DISCLAIMER.md)** — **Read this first** — liability waiver

## Makefile Targets

| Target | Description |
|---|---|
| `make install` | Idempotently install into `~/.kimi` |
| `make verify` | Confirm installation integrity |
| `make check` | Validate configs with the validator |
| `make sync` | Verify mirror files are in sync |
| `make test` | Run pytest suite |
| `make uninstall` | Remove installed files (preserves secrets) |

## License

See [LICENSE](./LICENSE).
