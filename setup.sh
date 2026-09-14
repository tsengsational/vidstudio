#!/usr/bin/env bash
#
# setup.sh — bootstrap the AI video-editing studio.
#
# Idempotent: safe to run repeatedly. It will
#   1. clone (or update) the two vendored tools into tools/
#   2. install their dependencies
#   3. verify ffmpeg/ffprobe are on PATH
#   4. verify the ElevenLabs API key is available to video-use
#
# Nothing here is destructive: existing clones are `git pull`-ed, never wiped.

set -uo pipefail

# --- locations ---------------------------------------------------------------
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS="$ROOT/tools"
VIDEO_USE="$TOOLS/video-use"
HYPERFRAMES="$TOOLS/hyperframes"

VIDEO_USE_REPO="https://github.com/browser-use/video-use.git"
HYPERFRAMES_REPO="https://github.com/heygen-com/hyperframes.git"

# --- pretty output -----------------------------------------------------------
ok()   { printf '  \033[32m✓\033[0m %s\n' "$*"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$*"; }
err()  { printf '  \033[31m✗\033[0m %s\n' "$*"; }
step() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }

has() { command -v "$1" >/dev/null 2>&1; }

WARNINGS=0
note_warn() { WARNINGS=$((WARNINGS + 1)); warn "$*"; }

# --- 1. clone or update ------------------------------------------------------
clone_or_update() {
  local name="$1" dir="$2" repo="$3"
  if [ -d "$dir/.git" ]; then
    ok "$name present — updating"
    git -C "$dir" pull --ff-only 2>&1 | sed 's/^/    /' || note_warn "$name: git pull failed (continuing with current checkout)"
  else
    step "Cloning $name"
    git clone "$repo" "$dir" 2>&1 | sed 's/^/    /' || { err "$name: clone failed"; return 1; }
    ok "$name cloned"
  fi
}

step "Vendoring tools into tools/"
mkdir -p "$TOOLS"
clone_or_update "video-use"   "$VIDEO_USE"   "$VIDEO_USE_REPO"
clone_or_update "hyperframes" "$HYPERFRAMES" "$HYPERFRAMES_REPO"

# --- 2a. video-use deps (Python via uv) --------------------------------------
step "Installing video-use dependencies (Python)"
if has uv; then
  ( cd "$VIDEO_USE" && uv sync ) && ok "uv sync complete" || note_warn "uv sync failed — check output above"
elif has pip; then
  note_warn "uv not found — falling back to 'pip install -e .'"
  ( cd "$VIDEO_USE" && pip install -e . ) && ok "pip install complete" || note_warn "pip install failed"
else
  note_warn "Neither uv nor pip found. Install uv: https://docs.astral.sh/uv/getting-started/installation/"
fi

# --- 2b. hyperframes deps (Node 22 + Bun) ------------------------------------
step "Installing hyperframes dependencies (Node 22 + Bun)"
if has node; then
  NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0)"
  if [ "${NODE_MAJOR:-0}" -ge 22 ]; then
    ok "Node $(node --version) (>= 22)"
  else
    note_warn "Node $(node --version) found; hyperframes needs Node >= 22"
  fi
else
  note_warn "node not found — install Node 22+: https://nodejs.org/"
fi

if has bun; then
  ( cd "$HYPERFRAMES" && bun install && bun run build ) \
    && ok "bun install && build complete" \
    || note_warn "bun install/build failed — check output above"
else
  note_warn "bun not found. Install Bun: https://bun.sh/  (curl -fsSL https://bun.sh/install | bash)"
fi

# --- 3. ffmpeg ---------------------------------------------------------------
step "Verifying ffmpeg toolchain"
if has ffmpeg && has ffprobe; then
  ok "$(ffmpeg -version 2>/dev/null | head -1)"
  ok "ffprobe on PATH"
else
  note_warn "ffmpeg/ffprobe not found on PATH. Install:"
  warn "    macOS:   brew install ffmpeg"
  warn "    Windows: winget install Gyan.FFmpeg   (or: choco install ffmpeg)"
  warn "    Linux:   sudo apt install ffmpeg"
fi

# --- 4. ElevenLabs key -------------------------------------------------------
step "Verifying ElevenLabs API key"
ENV_FILE="$VIDEO_USE/.env"
KEY_OK=0
if [ -n "${ELEVENLABS_API_KEY:-}" ]; then
  ok "ELEVENLABS_API_KEY found in environment"
  KEY_OK=1
elif [ -f "$ENV_FILE" ] && grep -q '^ELEVENLABS_API_KEY=.\+' "$ENV_FILE" 2>/dev/null; then
  ok "ELEVENLABS_API_KEY found in tools/video-use/.env"
  KEY_OK=1
fi
if [ "$KEY_OK" -eq 0 ]; then
  note_warn "ELEVENLABS_API_KEY not set."
  warn "    Get one at https://elevenlabs.io/app/settings/api-keys, then either:"
  warn "      export ELEVENLABS_API_KEY=sk_...            (shell env), or"
  warn "      echo 'ELEVENLABS_API_KEY=sk_...' >> tools/video-use/.env"
  if [ ! -f "$ENV_FILE" ] && [ -f "$VIDEO_USE/.env.example" ]; then
    cp "$VIDEO_USE/.env.example" "$ENV_FILE" && ok "Seeded tools/video-use/.env from .env.example — add your key"
  fi
fi

# --- summary -----------------------------------------------------------------
step "Setup summary"
if [ "$WARNINGS" -eq 0 ]; then
  ok "All checks passed. Studio is ready."
else
  warn "$WARNINGS warning(s) above — resolve them before editing. Re-run ./setup.sh anytime; it's idempotent."
fi
exit 0
