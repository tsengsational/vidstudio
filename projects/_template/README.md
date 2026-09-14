# Project template

Copy this directory to start a new project:

```bash
cp -r projects/_template "projects/$(date +%Y-%m-%d)-my-slug"
```

Then drop your source footage into `raw/` and tell Claude Code **"edit this."**

```
raw/           source footage — dropped here, never modified
edit/          transcripts, packed transcript, edl.json, master.srt, cut artifacts
compositions/  hyperframes HTML motion-graphics (one subdir per graphic)
renders/       preview.mp4 (1080×1920) and final.mp4 (native resolution)
```

See the studio house rules in the repo-root [`CLAUDE.md`](../../CLAUDE.md).
