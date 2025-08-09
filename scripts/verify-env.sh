#!/usr/bin/env bash
# scripts/verify-env.sh
# Verifies Node, npm, pnpm (if used), and Nx (workspace) are installed & discoverable.

set -u  # no -e so we can collect all errors
ERRORS=0

say() { printf "\n\033[1m%s\033[0m\n" "$1"; }
ok()  { printf "  ✔ %s\n" "$1"; }
warn(){ printf "  ⚠ %s\n" "$1"; }
err() { printf "  ✖ %s\n" "$1"; ERRORS=$((ERRORS+1)); }

# Ensure we're at a project root with package.json
if [[ ! -f "package.json" ]]; then
  err "No package.json found in current directory. Run from repo root."
  echo
  echo "Summary: $ERRORS error(s)."
  exit 1
fi

say "Reading project metadata"
PKG_MANAGER="$(node -e "try{console.log(require('./package.json').packageManager||'');}catch(e){console.log('');}" 2>/dev/null || true)"
ENGINE_NODE="$(node -e "try{console.log((require('./package.json').engines||{}).node||'');}catch(e){console.log('');}" 2>/dev/null || true)"
NX_DECLARED="$(node -e "try{const p=require('./package.json');console.log((p.devDependencies&&p.devDependencies.nx)||(p.dependencies&&p.dependencies.nx)||'');}catch(e){console.log('');}" 2>/dev/null || true)"

[[ -n "$PKG_MANAGER" ]] && ok "packageManager: $PKG_MANAGER" || warn "No packageManager field in package.json"
[[ -n "$ENGINE_NODE" ]] && ok "engines.node: $ENGINE_NODE" || warn "No engines.node specified"

say "Checking Node.js"
if command -v node >/dev/null 2>&1; then
  NODE_V="$(node -v 2>/dev/null || true)"
  ok "node found ($NODE_V)"
else
  err "node is not installed or not on PATH"
fi

say "Checking npm"
if command -v npm >/dev/null 2>&1; then
  NPM_V="$(npm -v 2>/dev/null || true)"
  ok "npm found (v$NPM_V)"
else
  err "npm is not installed or not on PATH"
fi

USE_PNPM=false
if [[ -f "pnpm-lock.yaml" ]] || [[ "$PKG_MANAGER" == pnpm@* ]]; then
  USE_PNPM=true
fi

if $USE_PNPM; then
  say "Checking pnpm (repo appears to use pnpm)"
  if command -v pnpm >/dev/null 2>&1; then
    PNPM_V="$(pnpm -v 2>/dev/null || true)"
    ok "pnpm found (v$PNPM_V)"
  else
    warn "pnpm not found on PATH"
    if command -v corepack >/dev/null 2>&1; then
      warn "Try: corepack enable"
    fi
    err "pnpm required but missing"
  fi
else
  say "pnpm check"
  ok "Repo does not appear to require pnpm (no lockfile/packageManager=pnpm)"
fi

say "Checking Nx (workspace/local)"
# Heuristics: Nx workspace usually has nx.json; local binary is node_modules/.bin/nx
[[ -f "nx.json" ]] && ok "nx.json found (Nx workspace detected)" || warn "nx.json not found (may not be an Nx workspace)"

if [[ -x "node_modules/.bin/nx" ]]; then
  NX_V="$('./node_modules/.bin/nx' --version 2>/dev/null || true)"
  [[ -n "$NX_V" ]] && ok "Local Nx CLI found (v$NX_V)" || err "Local Nx CLI exists but version check failed"
else
  warn "Local Nx CLI not found at node_modules/.bin/nx (have you installed deps?)"
  # Try non-install checks without fetching from the network
  if command -v npx >/dev/null 2>&1; then
    # npx might fetch; we avoid auto-install. Just inform the user instead:
    warn "Run your package manager install and re-check (e.g., 'pnpm install' or 'npm ci')"
    err "Nx not installed locally"
  else
    err "npx not available to probe Nx"
  fi
fi

say "Summary"
if [[ $ERRORS -eq 0 ]]; then
  ok "Environment looks good ✅"
  echo
  echo "All required tools are available. You can proceed with development."
else
  err "Found $ERRORS error(s). Please fix the issues above before continuing."
  echo
  echo "Common fixes:"
  echo "- Install Node.js: https://nodejs.org/"
  echo "- Enable corepack for pnpm: corepack enable"
  echo "- Install dependencies: pnpm install (or npm ci)"
fi
echo
exit $ERRORS