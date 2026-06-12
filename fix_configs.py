import re
import sys

def fix_toml(file_path):
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()
    except FileNotFoundError:
        print(f"Not found: {file_path}")
        return

    # 1. Remove hooks = []
    content = re.sub(r"^hooks\s*=\s*\[\]\n", "", content, flags=re.MULTILINE)

    # 2. Add default_permission_mode = "manual" to top level
    if "default_permission_mode" not in content:
        content = re.sub(
            r"^(default_model\s*=\s*.*)$",
            r"\1\ndefault_permission_mode = \"manual\"",
            content,
            flags=re.MULTILINE
        )

    # 3. Remove [services.moonshot_search] up to but not including [mcp.client]
    # Let's find the boundaries more safely.
    # The original file has [services.moonshot_search], [services.moonshot_search.oauth], [services.moonshot_fetch], [services.moonshot_fetch.oauth]
    content = re.sub(r"\[services\.moonshot_search\](.*?)(\n\[mcp\.client\])", r"\2", content, flags=re.DOTALL)

    # 4. Remove [providers."managed:kimi-code".oauth] block
    content = re.sub(r"\[providers\.\"managed:kimi-code\"\.oauth\]\nstorage = \"file\"\nkey = \"oauth/kimi-code\"\n", "", content)

    # 5. Add [thinking] mode = "auto"
    if "[thinking]" not in content:
        content += "\n[thinking]\nmode = \"auto\"\n"

    # 6. Add [[permission.rules]] blocks
    if "[[permission.rules]]" not in content:
        content += """
[[permission.rules]]
decision = "allow"
pattern = "Read"

[[permission.rules]]
decision = "deny"
pattern = "Bash(rm -rf*)"
"""

    # 7. Add [[hooks]] block
    if "[[hooks]]" not in content:
        content += """
[[hooks]]
event = "PreToolUse"
matcher = "Bash"
command = "node ~/.kimi-code/hooks/check-bash.mjs"
timeout = 5
"""

    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"Fixed {file_path}")

for f in ["config/config.toml", "config/kimi.toml"]:
    fix_toml(f)
