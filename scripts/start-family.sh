#!/usr/bin/env bash
# Start God's Eye View on http://localhost:4173 and open it in the browser.
# Closing this terminal (or Ctrl+C) stops the dev server.
set -u

URL="http://localhost:4173"
REPO="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
cd "$REPO" || exit 1

# nvm.sh can return non-zero (e.g. an unresolved default alias), so don't
# treat sourcing it as fatal; `nvm use` picks up .nvmrc.
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
# shellcheck disable=SC1091
. "$NVM_DIR/nvm.sh" || true
nvm use >/dev/null || { echo "nvm use failed (see .nvmrc)"; read -r -p "Press Enter to close"; exit 1; }
echo "Node $(node --version) in $REPO"

up() { curl -s -o /dev/null -m 2 "$URL/"; }

if up; then
  echo "Server already running; opening $URL"
  xdg-open "$URL" >/dev/null 2>&1 &
  exit 0
fi

# Own process group so the whole npm -> vite tree can be stopped together.
setsid npm run dev &
SERVER_PID=$!
cleanup() { kill -TERM -- "-$SERVER_PID" 2>/dev/null; }
trap cleanup EXIT
trap 'exit 130' INT TERM HUP

for _ in $(seq 1 60); do
  up && break
  kill -0 "$SERVER_PID" 2>/dev/null || { echo "Dev server exited"; read -r -p "Press Enter to close"; exit 1; }
  sleep 1
done

if up; then
  xdg-open "$URL" >/dev/null 2>&1 &
  echo "Opened $URL. Close this window or press Ctrl+C to stop the server."
else
  echo "Server did not come up within 60s; check the log above."
fi

wait "$SERVER_PID"
