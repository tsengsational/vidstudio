# Video Studio — House Rules

A personal AI video-editing studio, orchestrated by Claude Code. You (Claude) are
the editor. These are the non-negotiable rules of the room. Read them before touching
any footage.

The `video-studio` skill (`.claude/skills/video-studio/SKILL.md`) is the conductor —
it decides when to delegate to **video-use** (transcript-based cutting) vs
**hyperframes** (motion graphics). This file is the law that skill operates under.

---

## 1. Output format — preserve the source

- **Vertical 9:16.** Every deliverable is portrait.
- **PRESERVE the source resolution. Never downscale.** If the source is 4K vertical
  (2160×3840), the final render is 4K vertical. If it's 1440×2560, that's what ships.
- **1080×1920 is the FLOOR, and only for quick previews.** Never deliver a preview
  as the final. Previews exist to make a fast decision; finals are always native res.
- ⚠️ **Override video-use's default.** `tools/video-use/helpers/render.py` defaults
  to a 1080p scale from any source. That default is WRONG for this studio. Always
  render finals at native resolution — probe the source with `ffprobe` first and pass
  the source's real width/height, or strip the downscale from the extract/scale step.
  The only time 1080×1920 is acceptable is a `--preview` pass.

## 2. Edit on the TRANSCRIPT first, never the timeline

The order is fixed and never skipped:

1. **Transcribe** the source (video-use → ElevenLabs Scribe, word-level timestamps).
2. **Propose a cut in plain English** — filler words, silences, false starts, retakes,
   described as human-readable time ranges ("cut 0:12–0:14, the 'umm' before the demo").
3. **I confirm.** You wait. No exceptions.
4. **Execute** the cut (produce the EDL, then render).

**Never render before I approve the plan.** Ask → confirm → execute. If you're unsure
whether you have approval, you don't — ask again.

## 3. Subtitles

- **Short chunks** (≈2 words per line by default; adapt to content).
- **Burned in LAST in the filter chain**, after every overlay/graphic. Subtitles
  applied before overlays get hidden behind them — a silent failure. This is a hard
  rule inherited from video-use and it is not negotiable.

## 4. Project layout

Every project lives in `projects/<YYYY-MM-DD-slug>/`:

```
projects/<YYYY-MM-DD-slug>/
├── raw/           ← source footage, dropped here, NEVER modified
├── edit/          ← transcripts, packed transcript, EDL, cut artifacts, master.srt
├── compositions/  ← hyperframes HTML motion-graphics projects (one dir per graphic)
└── renders/       ← preview.mp4 (1080×1920) and final.mp4 (native resolution)
```

- `raw/` is immutable. Sources are read-only inputs; you never write into `raw/`.
- Copy `projects/_template/` to start a new project, or the skill scaffolds it for you.
- The date is the day the project starts. The slug is a short kebab-case description.

## 5. Working discipline (inherited from the tools)

- **Cache transcripts.** Never re-transcribe a source unless the file itself changed.
- **Never cut inside a word.** Snap every cut edge to a Scribe word boundary; pad
  edges 30–200ms to absorb timestamp drift.
- **30ms audio fades at every cut** — otherwise audible pops.
- **Per-segment extract → lossless concat**, not a single-pass filtergraph, whenever
  overlays are involved (avoids double-encoding).
- **Self-verify before showing me.** Sanity-check the rendered output (cut boundaries,
  audio, subtitle visibility, native resolution via `ffprobe`) before presenting it.

## 6. The two tools

- **`tools/video-use/`** — transcript-based cutting (Python, `uv sync`, needs
  `ELEVENLABS_API_KEY` in `tools/video-use/.env`). Helpers: `transcribe.py`,
  `pack_transcripts.py`, `timeline_view.py`, `render.py`, `grade.py`. Its own
  `SKILL.md` holds the full production ruleset — read it before rendering.
- **`tools/hyperframes/`** — HTML → MP4 motion graphics (Node 22 + Bun,
  `bun install && bun run build`; drive via `npx hyperframes`). Use for lower-thirds,
  callouts, kinetic typography, data cards, transparent-WebM overlays.

Run `./setup.sh` to clone/update both and verify the toolchain. It's idempotent.

---

**The prime directive:** transcript first, plain-English cut, my approval, then render —
vertical, native resolution, subtitles last.
