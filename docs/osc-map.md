# OSC map — authoritative reference

This file is the **single source of truth** for every OSC port and address in the project.
When something changes, change it **here first**, then update the Python sender, the
SuperCollider responders, and the TouchDesigner *OSC In* node to match.

> **Everything below is a placeholder convention marked `TODO`.** Replace with the real
> values from your patches. None of these addresses were measured from your code — they are
> a suggested, consistent naming scheme.

---

## Ports

| Link | Port (UDP) | Status | Set in |
|---|---|---|---|
| Python → SuperCollider (`sclang`) | `57120` | default, OK | Python sender; `sclang` listens here by default |
| Python → TouchDesigner | `7000` | **TODO confirm** | TD *OSC In* CHOP/DAT **and** Python sender |
| `sclang` → `scsynth` (internal) | `57110` | default, internal | SuperCollider internal — not used by Python |

Address namespace convention: `/sc/<module>/<param>` for sound, `/td/<group>/<param>` for
visuals _(TODO: confirm your TD address scheme)_.

---

## Sound addresses (SuperCollider)

### 1. Spectral Sculpture — `/sc/spectral/...`

| Address | Type | Range | Driven by (feature) | Maps to |
|---|---|---|---|---|
| `/sc/spectral/blur` | float | 0–1 | `torso_openness` | spectral smear amount |
| `/sc/spectral/shift` | float | −1–1 | `hand_height` | bin / frequency shift |
| `/sc/spectral/erode` | float | 0–1 | `motion_energy` | magnitude erosion |
| `/sc/spectral/freeze` | int | 0 / 1 | `stillness` | spectral freeze gate |
| `/sc/spectral/amp` | float | 0–1 | `presence` | module level |

### 2. Spatial Separation — `/sc/spatial/...`

| Address | Type | Range | Driven by (feature) | Maps to |
|---|---|---|---|---|
| `/sc/spatial/x` | float | −1–1 | `centroid_x` | azimuth / pan |
| `/sc/spatial/y` | float | −1–1 | `depth` | front–back |
| `/sc/spatial/spread` | float | 0–1 | `arm_span` | source spread / decorrelation |
| `/sc/spatial/rotate` | float | 0–1 | `angular_velocity` | field rotation speed |

### 3. Voice Glitch — `/sc/voice/...`

| Address | Type | Range | Driven by (feature) | Maps to |
|---|---|---|---|---|
| `/sc/voice/scrub` | float | 0–1 | `hand_x` | buffer playback position |
| `/sc/voice/density` | float | 0–1 | `motion_energy` | grain density |
| `/sc/voice/jitter` | float | 0–1 | `acceleration` | position / pitch jitter |
| `/sc/voice/pitch` | float | −12–12 | `head_height` | grain transposition (semitones) |
| `/sc/voice/gate` | int | 0 / 1 | `gesture_trigger` | stutter on/off |

### 4. Shepard Tone — `/sc/shepard/...`

| Address | Type | Range | Driven by (feature) | Maps to |
|---|---|---|---|---|
| `/sc/shepard/rate` | float | −1–1 | `velocity_y` | glide direction & speed |
| `/sc/shepard/depth` | float | 0–1 | `crouch_extension` | active octave count |
| `/sc/shepard/tilt` | float | 0–1 | `lean` | spectral tilt |
| `/sc/shepard/amp` | float | 0–1 | `presence` | module level |

### 5. Amplitude Feedback Loop — `/sc/feedback/...`

| Address | Type | Range | Driven by (feature) | Maps to |
|---|---|---|---|---|
| `/sc/feedback/gain` | float | 0–1 | `proximity` | feedback loop gain |
| `/sc/feedback/threshold` | float | 0–1 | `stillness` | amplitude threshold |
| `/sc/feedback/release` | float | 0–1 | `motion_energy` | decay time |
| `/sc/feedback/ceiling` | float | 0–1 | manual | hard safety ceiling (keep low) |

---

## Visual addresses (TouchDesigner)

_(TODO: list the addresses TD actually listens for, or note that TD reads the same
`/sc/...` stream. Fill this in once the patch is settled.)_

| Address | Type | Range | Driven by (feature) | Maps to |
|---|---|---|---|---|
| `/td/...` | — | — | — | **TODO** |

---

## How to keep this in sync

1. Edit this table first.
2. Update `supercollider/osc/` responders (`OSCdef` addresses).
3. Update the Python sender's address constants.
4. Update the TouchDesigner *OSC In* node + any DAT that parses addresses.
5. Commit all four together so the contract never drifts.
