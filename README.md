# RimeConfigurator · 鼠须管配置器

A native macOS GUI for configuring [Squirrel (鼠须管)](https://github.com/rime/squirrel), the RIME input method engine on macOS. No more hand-editing YAML — manage your input schemas, tweak appearance, and adjust behavior all from one clean window.

> **Requires** macOS 13 Ventura or later · Squirrel must already be installed

---

## Features

### 📋 Input Schemas
- See every schema installed in both `~/Library/Rime` and Squirrel's SharedSupport bundle
- Enable or disable schemas with a single click
- Drag rows to reorder — the first schema in the list becomes the default
- Search the available schema library by name or schema ID

### 🎨 Appearance
- Live **candidate-window preview** that updates as you change settings
- Pick a **color scheme** from a visual card grid — built-in schemes loaded directly from `squirrel.yaml`
- Configure **candidate font** and **label font** (family + point size) using a native font picker
- Toggle between **stacked** (vertical) and **linear** (horizontal) candidate layout
- Set **text orientation** (horizontal / vertical)
- Fine-grained geometry sliders: corner radius, highlight corner radius, border height/width, line spacing, candidate spacing, shadow size
- Behavior toggles in the Appearance panel: inline preedit, inline candidate, translucency, show paging

### ⚙️ Behavior
- Choose **candidates per page** (1–9) with a visual button row
- Detailed toggle rows for input behavior — inline preedit, inline candidate, translucency, show paging — each with a description of what it does
- One-click shortcut to **open the Rime config directory** in Finder

### 💾 Save & Deploy
- Press **⌘⇧R** (or the toolbar button) to write config and trigger a Rime redeploy
- After saving, a sheet shows the exact YAML written to disk (`squirrel.custom.yaml` and `default.custom.yaml`) so you always know what changed
- Deployment uses Squirrel's native notification mechanism — same as clicking "重新部署" in the menu bar icon

---

## Screenshots

| Schemas | Appearance | Behavior |
|---------|------------|----------|
| *(add screenshot)* | *(add screenshot)* | *(add screenshot)* |

---

## Requirements

| Requirement | Version |
|-------------|---------|
| macOS | 13 Ventura+ |
| Squirrel (鼠须管) | Any recent version |
| Xcode / Swift | Swift 5.9+ |

---

## Build & Run

```bash
git clone https://github.com/bryanzk/RimeConfigurator.git
cd RimeConfigurator
swift run
```

Or open in Xcode:

```bash
open Package.swift
```

Then press **⌘R** to build and run.

---

## How It Works

RimeConfigurator reads from and writes to the standard Rime user directory:

| File | Purpose |
|------|---------|
| `~/Library/Rime/squirrel.custom.yaml` | Appearance & behavior overrides |
| `~/Library/Rime/default.custom.yaml` | Schema list & page size |
| `~/Library/Rime/*.schema.yaml` | Installed user schemas (read-only) |
| `/Library/Input Methods/Squirrel.app/…/SharedSupport/` | Built-in schemas & color schemes (read-only) |

After saving, it sends a distributed notification to Squirrel to trigger a redeploy. If the notification doesn't land, it also touches `installation.yaml` and attempts to invoke the Squirrel binary with `--reload` as a fallback.

> **Note:** Per-app input overrides (`app_options`) are not yet configurable in the GUI. You can still edit them directly in `squirrel.custom.yaml` — click "在访达中打开配置目录" in the Behavior tab to jump straight there.

---

## Dependencies

- [Yams](https://github.com/jpsim/Yams) — YAML parsing & serialization

---

## License

MIT