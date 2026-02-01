#!/bin/bash

# Add Caps Lock hyper key rule to Karabiner-Elements config
# This adds the rule directly to karabiner.json (auto-enabled)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KARABINER_CONFIG="$HOME/.config/karabiner/karabiner.json"
RULES_FILE="$SCRIPT_DIR/caps_lock_hyper.json"

# Ensure karabiner config directory exists
mkdir -p "$HOME/.config/karabiner"

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "jq is required. Installing via Homebrew..."
    brew install jq
fi

# Read our rule from the rules file
RULE=$(jq '.rules[0]' "$RULES_FILE")
RULE_DESC=$(echo "$RULE" | jq -r '.description')

# If karabiner.json doesn't exist, create a minimal config
if [ ! -f "$KARABINER_CONFIG" ]; then
    echo "Creating new Karabiner config..."
    cat > "$KARABINER_CONFIG" << 'EOF'
{
    "profiles": [
        {
            "complex_modifications": {
                "rules": []
            },
            "name": "Default profile",
            "selected": true
        }
    ]
}
EOF
fi

# Check if the rule already exists (by description)
EXISTING=$(jq --arg desc "$RULE_DESC" '.profiles[0].complex_modifications.rules | map(select(.description == $desc)) | length' "$KARABINER_CONFIG")

if [ "$EXISTING" -gt 0 ]; then
    echo "✓ Caps Lock hyper key rule already enabled"
else
    echo "Adding Caps Lock hyper key rule..."
    # Add the rule to the beginning of the rules array
    jq --argjson rule "$RULE" '.profiles[0].complex_modifications.rules = [$rule] + .profiles[0].complex_modifications.rules' "$KARABINER_CONFIG" > "$KARABINER_CONFIG.tmp"
    mv "$KARABINER_CONFIG.tmp" "$KARABINER_CONFIG"
    echo "✓ Caps Lock → Ctrl+Opt+Cmd rule enabled"
fi
