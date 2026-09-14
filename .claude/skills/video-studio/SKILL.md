---
name: video-studio
description: The conductor for a personal AI video-editing studio. Use when the user drops footage into a project's raw/ and says "edit this" (or similar). Orchestrates transcript-based cutting via video-use and motion-graphics via hyperframes, producing a vertical 9:16 render at native resolution. Transcribe → propose a plain-English cut → WAIT for approval → execute → suggest graphics → render. Never renders before the user approves.
---

# Video Studio (conductor)

You are the conductor of a personal video-editing studio. You do not do the low-level
work yourself — you **delegate**: cutting to **video-use**, motion graphics to
**hyperframes**. You decide which tool fits each need, run the pipeline in order, and
enforce the house rules in [`CLAUDE.md`](../../../CLAUDE.md).

**Read `CLAUDE.md` and `tools/video-use/SKILL.md` before rendering anything.** The house
rules override any conflicting default in the underlying tools (most importantly:
**native resolution, never downscale** — video-use's `render.py` defaults to 1080p).

## The prime directive

**Transcript first → plain-English cut → WAIT for the user's OK → execute → render.**
Never render before the user approves the cut. Ask → confirm → execute. If you're not
certain you have approval, you don't — ask.

## Delegation map — who does what

| Need | Tool | How you invoke it |
|------|------|-------------------|
| Transcribe, find filler/silence/retakes, cut, grade, burn subtitles | **video-use** | `tools/video-use/helpers/*.py` (`transcribe.py`, `pack_transcripts.py`, `timeline_view.py`, `render.py`, `grade.py`) |
| Motion graphics: lower-thirds, callouts, kinetic type, data cards, transparent overlays | **hyperframes** | scaffold an HTML composition in `compositions/`, render to MP4/WebM via `npx hyperframes` |

**Rule of thumb:** if it's about *what to keep and in what order* (speech, timing,
cuts, captions) → video-use. If it's about *adding a designed visual on top* → hyperframes.
Graphics are always built AFTER the cut is locked, and composited as overlays.

## Preconditions (check once per session, quietly)

- `ELEVENLABS_API_KEY` resolves (env or `tools/video-use/.env`). If missing, ask the
  user to paste one; write it to `tools/video-use/.env`, never into a project.
- `ffmpeg` + `ffprobe` on PATH; video-use Python deps installed; Bun + Node 22+ for
  hyperframes. If anything's missing, tell the user to run `./setup.sh` and stop.

## The pipeline

### 0. Locate / scaffold the project

When the user drops a file and says "edit this":

- If they dropped it into an existing `projects/<YYYY-MM-DD-slug>/raw/`, use that project.
- Otherwise scaffold one: copy `projects/_template/` to
  `projects/<today>-<slug>/` (today = `2026-09-08`-style date; slug = short kebab
  description you infer or ask for), and move the source into its `raw/`.
- **Never modify files in `raw/`.** All work goes in `edit/`, `compositions/`, `renders/`.

### 1. Transcribe (video-use)

- `ffprobe` every source in `raw/` — record real **width, height, fps** (you need
  native dimensions for the final render).
- Transcribe into the project's `edit/`:
  `python tools/video-use/helpers/transcribe.py <raw/source> ` (cached — never
  re-transcribe an unchanged source), then
  `python tools/video-use/helpers/pack_transcripts.py --edit-dir projects/<proj>/edit`
  to produce `edit/takes_packed.md`, your primary reading view.
- Use `timeline_view.py` only at decision points (ambiguous pauses, retake compares),
  not as a scan tool.

### 2. Propose the cut in PLAIN ENGLISH — then STOP

Read `takes_packed.md`. Propose a filler / silence / retake cut as human-readable
ranges the user can react to, e.g.:

> Proposed cut (0:47 → 0:31):
> - Drop **0:03–0:05** — "umm, so, yeah" before the hook
> - Drop **0:19–0:22** — dead air / silence between takes
> - Use the **second** take of the CTA (0:38–0:44), the first has a stumble at 0:35
> - Tighten the pause at **0:28** by ~400ms

**Then WAIT.** Do not build an EDL, do not render. Get the user's OK (they may edit the
plan). Only after explicit approval do you continue.

### 3. Execute the cut (video-use)

- Write `edit/edl.json` reflecting the approved ranges (word-boundary snapped, padded
  30–200ms). See the EDL format in `tools/video-use/SKILL.md`.
- Render a **preview** first (fast, 1080×1920 allowed here only):
  `render.py edit/edl.json -o renders/preview.mp4 --preview`
- Show the preview. Iterate on natural-language feedback. Never re-transcribe.

### 4. Suggest graphics (hyperframes) — 2–3 spots

Once the cut reads well, proactively suggest **2–3 specific spots** that want a graphic,
tied to timecodes and purpose, e.g.:

> Three spots I'd add a graphic:
> 1. **0:00–0:03** — animated title card over the hook
> 2. **0:14** — lower-third naming the feature as it's first mentioned
> 3. **0:25–0:29** — a stat callout ("10× faster") synced to the claim

Offer to build them. For each approved graphic:

- Scaffold a composition dir: `compositions/<slot>/` and init it with hyperframes
  (`npx hyperframes init compositions/<slot> --example blank --non-interactive --skip-skills`).
- Author the HTML composition to the studio's palette/brand (ask if unknown).
- Render it: `npx hyperframes render compositions/<slot> -o compositions/<slot>/render.mp4`
  (use `--format webm` when the overlay needs alpha/transparency).
- Add it to `edl.json` as an overlay (PTS-shifted to its window; see video-use rules).
- Build independent graphics in **parallel** sub-agents (Agent tool), one per slot.

### 5. Render vertical at NATIVE resolution (final)

- Compose: cut segments → grade (if requested) → overlays → **subtitles LAST**.
- **Final render is native resolution, not 1080p.** Pass the source's real
  width/height (from step 1's `ffprobe`); do not use `render.py`'s default 1080p scale.
  Only `renders/preview.mp4` may be 1080×1920.
- Output to `renders/final.mp4`.

### 6. Self-verify, then present

Before showing the user: `ffprobe renders/final.mp4` to confirm it's 9:16 at native
resolution, spot-check cut boundaries and audio (no pops), and confirm subtitles are
visible over overlays. Only present once it passes. Never present the preview as final.

## Hard rules (never violate — see CLAUDE.md and video-use/SKILL.md)

1. Never render before the user approves the plain-English cut.
2. Vertical 9:16, **native resolution** for finals; 1080×1920 is previews only.
3. Subtitles burned in **LAST**, after overlays. Short chunks.
4. Never cut inside a word; pad edges 30–200ms; 30ms audio fades at every cut.
5. `raw/` is immutable. All outputs in `edit/`, `compositions/`, `renders/`.
6. Cache transcripts — never re-transcribe an unchanged source.
7. Per-segment extract → lossless concat when overlays are present.
