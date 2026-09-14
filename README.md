# Video Studio

A personal, AI-orchestrated video-editing studio. Drop raw footage into a project,
tell Claude Code **"edit this,"** and it transcribes, proposes a plain-English cut,
waits for your approval, then cuts, adds motion graphics, and renders a vertical 9:16
video at your source's native resolution.

Claude Code is the conductor. It delegates the actual work to two vendored open-source
tools and enforces a fixed set of house rules ([`CLAUDE.md`](CLAUDE.md)).

## How it works

```
        you: "edit this"
              │
              ▼
   ┌─────────────────────┐     transcript-based cutting
   │  video-studio skill │──▶  video-use   (transcribe · cut · grade · subtitle)
   │   (the conductor)   │
   │  .claude/skills/... │──▶  hyperframes (HTML → MP4 motion graphics)
   └─────────────────────┘
              │
              ▼
   vertical 9:16 render @ native resolution
```

- **[video-use](https://github.com/browser-use/video-use)** — transcript-driven editing.
  Transcribes with ElevenLabs Scribe, cuts on word boundaries, color-grades, burns
  subtitles. (Python)
- **[hyperframes](https://github.com/heygen-com/hyperframes)** — turns HTML/CSS into
  deterministic MP4 motion graphics: titles, lower-thirds, kinetic type, callouts.
  (Node 22 + Bun)

The workflow is always **transcribe → propose a cut in plain English → you approve →
execute → render.** Nothing renders before you sign off. See [`CLAUDE.md`](CLAUDE.md)
for the full house rules (native resolution, subtitles last, immutable `raw/`, etc.).

## Requirements

| Tool | Purpose | Install (Windows) |
|------|---------|-------------------|
| **git** | clone the vendored tools | pre-installed / [git-scm.com](https://git-scm.com) |
| **ffmpeg** (+ ffprobe) | all video/audio processing | `winget install Gyan.FFmpeg` |
| **uv** | Python deps for video-use | `winget install astral-sh.uv` |
| **Node 22+** | runtime for hyperframes | [nodejs.org](https://nodejs.org) |
| **Bun** | build/run hyperframes | `powershell -c "irm bun.sh/install.ps1 \| iex"` |
| **ElevenLabs API key** | transcription (Scribe) | [elevenlabs.io](https://elevenlabs.io/app/settings/api-keys) |

On macOS/Linux, use `brew` / your package manager for ffmpeg, uv, and Bun.

## Install

```bash
git clone <this-repo-url> vidstudio
cd vidstudio
./setup.sh
```

`setup.sh` is idempotent — run it anytime. It:
1. clones (or updates) `video-use` and `hyperframes` into `tools/`
2. installs their dependencies (`uv sync`, `bun install && bun run build`)
3. verifies ffmpeg/ffprobe and the ElevenLabs key

Add your ElevenLabs key so transcription works:

```bash
echo 'ELEVENLABS_API_KEY=sk_your_key_here' >> tools/video-use/.env
```

Re-run `./setup.sh` until every check is green.

> **Windows note:** if you install the tools *after* opening your terminal/app, they may
> not be on `PATH` yet. `source .studio-env.sh` adds them for the current shell, or just
> restart the terminal.

## Quickstart

```bash
# 1. Start a project (or let the assistant scaffold one)
cp -r projects/_template "projects/$(date +%Y-%m-%d)-my-clip"

# 2. Drop your footage into its raw/ folder
#    projects/2026-09-14-my-clip/raw/*.mp4

# 3. In Claude Code, say:
#    "edit this"
```

The assistant inventories the footage, proposes a cut in plain English, waits for your
OK, then cuts, suggests 2–3 spots for graphics, and renders vertical at native resolution.

## Project layout

```
vidstudio/
├── CLAUDE.md                    # house rules (the law)
├── setup.sh                     # idempotent toolchain bootstrap
├── .studio-env.sh               # puts the toolchain on PATH (source it)
├── .claude/skills/video-studio/ # the orchestrator skill
├── tools/                       # vendored video-use + hyperframes (git-ignored)
└── projects/
    ├── _template/               # starter structure for a new project
    └── <YYYY-MM-DD-slug>/
        ├── raw/                 # source footage — never modified
        ├── edit/                # transcripts, EDL, cut artifacts
        ├── compositions/        # hyperframes motion-graphics projects
        └── renders/             # preview.mp4 (1080×1920) + final.mp4 (native)
```

## What's tracked in git

Only the studio framework. Your footage, transcripts, and renders (`projects/*`), the
vendored tools (`tools/`), and secrets (`.env`) are all git-ignored — anyone can clone
this repo and run `./setup.sh` to rebuild the studio, while your media and API key stay
on your machine.

## Credits

Built on [video-use](https://github.com/browser-use/video-use) (Browser Use) and
[hyperframes](https://github.com/heygen-com/hyperframes) (HeyGen). See each tool's
repository for its own license.
