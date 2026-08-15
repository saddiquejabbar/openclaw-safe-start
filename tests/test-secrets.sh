#!/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

if find "$ROOT" -type f \
  \( -name '.env' -o -name '.env.*' -o -name 'auth.json' \
     -o -name 'openclaw.json' -o -name '*.pem' -o -name '*.p12' \
     -o -name '*.pfx' -o -name '*.sqlite' -o -name '*.db' \) \
  -print | grep -q .; then
  find "$ROOT" -type f \
    \( -name '.env' -o -name '.env.*' -o -name 'auth.json' \
       -o -name 'openclaw.json' -o -name '*.pem' -o -name '*.p12' \
       -o -name '*.pfx' -o -name '*.sqlite' -o -name '*.db' \) -print >&2
  fail "Secret/state-like file is present"
fi

patterns=(
  '-----BEGIN (RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----'
  'AKIA[0-9A-Z]{16}'
  'ASIA[0-9A-Z]{16}'
  'github_pat_[A-Za-z0-9_]{20,}'
  'gh[pousr]_[A-Za-z0-9]{30,}'
  'sk-proj-[A-Za-z0-9_-]{20,}'
  'sk-ant-[A-Za-z0-9_-]{20,}'
  'xox[baprs]-[A-Za-z0-9-]{20,}'
  '[0-9]{8,10}:[A-Za-z0-9_-]{35}'
)

for pattern in "${patterns[@]}"; do
  if rg -n --hidden --glob '!.git/**' --glob '!tests/test-secrets.sh' \
      --glob '!docs/CRITIQUE_PROMPT.md' -- "$pattern" "$ROOT"; then
    fail "High-confidence secret pattern found"
  fi
done

if rg -n --hidden --glob '!.git/**' --glob '!tests/test-secrets.sh' -- \
    '/Users/[^/[:space:]]+|[A-Za-z]:\\Users\\[^\\[:space:]]+' "$ROOT"; then
  fail "Personal absolute user path is present"
fi

printf 'PASS: no high-confidence secrets, local state, or personal user paths\n'
