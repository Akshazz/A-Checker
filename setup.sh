#!/usr/bin/env bash
# Storage Health Monitor — automated setup for macOS/Linux (XAMPP/LAMPP).
# Copies the web app into htdocs, generates a random API key, imports the
# database, wires up the agent config, and installs agent dependencies.
# You do not need to move or edit any files by hand — just run this script.

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Storage Health Monitor — Setup ==="
echo

# --- 1. Find/confirm htdocs ---
DEFAULT_HTDOCS=""
for candidate in "/opt/lampp/htdocs" "/Applications/XAMPP/xamppfiles/htdocs" "/Applications/XAMPP/htdocs" "$HOME/xampp/htdocs"; do
    if [ -d "$candidate" ]; then DEFAULT_HTDOCS="$candidate"; break; fi
done

if [ -n "$DEFAULT_HTDOCS" ]; then
    read -p "XAMPP htdocs folder found at $DEFAULT_HTDOCS — use it? [Y/n] " USE_DEFAULT
    if [[ "$USE_DEFAULT" =~ ^[Nn] ]]; then
        read -p "Enter full path to htdocs: " HTDOCS
    else
        HTDOCS="$DEFAULT_HTDOCS"
    fi
else
    read -p "Could not auto-detect htdocs. Enter full path to it: " HTDOCS
fi

if [ ! -d "$HTDOCS" ]; then
    echo "Error: '$HTDOCS' does not exist. Start XAMPP/install it first, then re-run this script."
    exit 1
fi

TARGET="$HTDOCS/storage-health-monitor"
echo "Installing app to: $TARGET"
mkdir -p "$TARGET"
cp -r "$SCRIPT_DIR/php/"* "$TARGET/"
mkdir -p "$TARGET/agent"
cp -r "$SCRIPT_DIR/agent/"* "$TARGET/agent/"

# --- 2. Generate a random API key ---
if command -v openssl >/dev/null 2>&1; then
    API_KEY=$(openssl rand -hex 32)
elif command -v python3 >/dev/null 2>&1; then
    API_KEY=$(python3 -c "import secrets; print(secrets.token_hex(32))")
else
    API_KEY=$(head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n')
fi
echo "Generated API key."

# --- 3. Find mysql client ---
MYSQL_BIN=""
for candidate in "/opt/lampp/bin/mysql" "/Applications/XAMPP/xamppfiles/bin/mysql" "mysql"; do
    if command -v "$candidate" >/dev/null 2>&1; then MYSQL_BIN="$candidate"; break; fi
    if [ -x "$candidate" ]; then MYSQL_BIN="$candidate"; break; fi
done
if [ -z "$MYSQL_BIN" ]; then
    read -p "Could not find the mysql client. Enter its full path: " MYSQL_BIN
fi

read -p "MySQL username [root]: " DB_USER
DB_USER="${DB_USER:-root}"
read -s -p "MySQL password [blank]: " DB_PASS
echo

# --- 4. Import schema with the generated key baked in ---
TMP_SQL=$(mktemp)
sed "s/__API_KEY__/$API_KEY/" "$SCRIPT_DIR/database/schema.sql" > "$TMP_SQL"

echo "Importing database..."
if [ -z "$DB_PASS" ]; then
    "$MYSQL_BIN" -u "$DB_USER" < "$TMP_SQL"
else
    "$MYSQL_BIN" -u "$DB_USER" -p"$DB_PASS" < "$TMP_SQL"
fi
rm -f "$TMP_SQL"

# --- 5. Write DB credentials into the deployed config.php ---
CONFIG_FILE="$TARGET/config.php"
sed -i.bak "s/define('DB_USER', 'root');/define('DB_USER', '$DB_USER');/" "$CONFIG_FILE"
ESCAPED_PASS=$(printf '%s\n' "$DB_PASS" | sed 's/[&/\]/\\&/g')
sed -i.bak "s/define('DB_PASS', '');/define('DB_PASS', '$ESCAPED_PASS');/" "$CONFIG_FILE"
rm -f "$CONFIG_FILE.bak"

# --- 6. Generate agent config.json automatically ---
AGENT_DIR="$TARGET/agent"
cat > "$AGENT_DIR/config.json" <<EOF
{
  "serverUrl": "http://localhost/storage-health-monitor/api/report.php",
  "apiKey": "$API_KEY",
  "smartctlPath": "smartctl",
  "devices": ["auto"]
}
EOF
echo "Agent config written to agent/config.json"

# --- 7. Install agent dependencies ---
if command -v npm >/dev/null 2>&1; then
    echo "Installing agent dependencies..."
    (cd "$AGENT_DIR" && npm install --silent)
else
    echo "Note: Node.js/npm not found. Install Node.js, then run: cd agent && npm install"
fi

# --- 8. Check for smartmontools ---
if ! command -v smartctl >/dev/null 2>&1; then
    echo
    echo "Note: 'smartctl' was not found on your PATH. Install smartmontools to scan drives:"
    echo "  macOS:  brew install smartmontools"
    echo "  Linux:  sudo apt install smartmontools   (or dnf/yum equivalent)"
fi

echo
echo "=== Setup complete ==="
echo "Dashboard:  http://localhost/storage-health-monitor/"
echo "Run a scan: cd agent && sudo npm run scan"
