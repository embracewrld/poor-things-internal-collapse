# Architecture

Detailed companion to the [Architecture section of the README](../README.md#architecture).
This document describes *how* body movement becomes sound and image — the shape of the
pipeline, the feature layer, and the things that matter for keeping latency low and the
system stable.

> Anything marked **TODO** is a value I still need to fill in from the real patches. I did
> not invent it.

---

## 1. Pipeline overview

```
   Camera ──▶ MediaPipe Pose ──▶ Feature extraction ──▶ OSC sender ──┬──▶ TouchDesigner ──▶ Projection
                (Python)            (Python)             (Python)     │
                                                                      └──▶ SuperCollider ──▶ Multichannel audio
```

The pipeline is **one-directional and real-time**. There is no feedback path from the
renderers back to the camera; the only feedback in the system is *musical* (the Amplitude
Feedback module) and *human* (the participant reacting to what they hear and see).

A visual version of this diagram lives at
[`docs/diagrams/dataflow.svg`](diagrams/dataflow.svg) for use in portfolio material.

---

## 2. Vision layer — MediaPipe (Python)

- **Input:** one camera stream.
- **Model:** MediaPipe Pose / Pose Landmarker — a full-body landmark tracker. _(TODO:
  confirm whether you use the legacy `mp.solutions.pose` API or the newer Tasks
  `PoseLandmarker`.)_
- **Output:** per-frame body landmarks (normalised coordinates), which are reduced to a
  compact **feature vector** before being sent over OSC. Sending raw landmarks is possible
  but noisy; the feature layer is what makes the mapping musical.

### Feature layer

The features below are the *intended* expressive parameters referenced throughout the
docs. Confirm the exact set you compute and list them here. _(TODO: reconcile with
`mediapipe/tracker.py`.)_

| Feature | Rough definition | Typical range | Used by |
|---|---|---|---|
| `centroid_x` | horizontal position of body centre | −1 … 1 | Spatial Separation |
| `depth` / `distance` | apparent distance / front–back | −1 … 1 | Spatial Separation, Feedback |
| `hand_height` | vertical hand position | 0 … 1 | Spectral, Voice |
| `head_height` | vertical head position | 0 … 1 | Voice (pitch) |
| `arm_span` | distance between hands | 0 … 1 | Spatial (spread) |
| `torso_openness` | shoulder/chest expansion | 0 … 1 | Spectral (blur) |
| `lean` | spine tilt from vertical | 0 … 1 | Shepard (tilt) |
| `motion_energy` | smoothed overall movement | 0 … 1 | Spectral, Voice, Feedback |
| `velocity_y` | vertical velocity (signed) | −1 … 1 | Shepard (rate) |
| `acceleration` / `jerk` | rate of change of motion | 0 … 1 | Voice (jitter) |
| `stillness` | inverse of motion, time-held | 0 … 1 | Spectral (freeze), Feedback |

**Smoothing.** Raw pose data jumps frame-to-frame. Apply smoothing (e.g. one-euro or a
simple low-pass) before mapping so the sound does not chatter. _(TODO: note your actual
filter + cutoff.)_

---

## 3. Transport layer — OSC

- **Protocol:** Open Sound Control over **UDP**, localhost (or a quiet LAN). _(TODO:
  confirm single-machine vs networked.)_
- **Why OSC:** it decouples the three programs. The renderers can crash, reload, or be
  re-opened without restarting the camera; the camera can be restarted without touching
  the patches.
- **Fan-out:** the Python sender transmits each message to **both** destinations
  (SuperCollider and TouchDesigner). Either keep two client sockets in Python, or run a
  small router — document whichever you chose. _(TODO.)_
- **Message rate:** send at a rate the renderers can absorb (camera frame rate is usually
  fine, e.g. 30 Hz). Avoid sending faster than you smooth. _(TODO: confirm rate.)_

The full port and address table is the **[OSC map](osc-map.md)** — the single source of
truth.

---

## 4. Sound layer — SuperCollider

- **`sclang`** receives OSC on **UDP 57120** (default) and uses `OSCdef` responders to
  route each address to the right synth parameter.
- **`scsynth`** (the audio server, internal port 57110) runs the five
  [sound modules](../README.md#sound-modules) as live synths whose controls are updated by
  `.set` from the responders.
- **Structure:** `main.scd` boots the server and loads everything; `synthdefs/` holds one
  `SynthDef` per module; `osc/` holds the responders. Keeping responders separate from
  SynthDefs means the OSC contract can change without editing the DSP. _(TODO: confirm this
  matches your real layout.)_

### Suggested signal flow inside SC

```
 OSCdef (/sc/<module>/<param>)  ──set──▶  module synths  ──▶  spatialiser  ──▶  limiter  ──▶  out
   spectral · spatial · voice · shepard · feedback
```

> Put a **limiter on the master bus.** The Amplitude Feedback module is designed to build;
> the limiter and a conservative `ceiling` are what keep it a sound and not an incident.

---

## 5. Image layer — TouchDesigner

- Receives the same OSC features on an **OSC In CHOP/DAT** (port **TODO: confirm**, e.g.
  7000) and maps them to the visual system.
- Runs in parallel with SuperCollider on the same feature stream, so image and sound stay
  locked to the same body without talking to each other.
- _(TODO: describe the visual system — what the features actually drive: particle system,
  feedback/displacement network, geometry, etc.)_

---

## 6. Latency & stability notes

- **End-to-end latency** = camera exposure + MediaPipe inference + feature smoothing + OSC
  hop + audio/render block. Keep each stage tight; smoothing and audio block size usually
  dominate.
- **Audio block / sample rate:** _(TODO: note your `s.options` — sample rate, block size,
  hardware buffer.)_
- **Camera frame rate:** _(TODO.)_
- **Failure modes to expect:** dropped OSC when a renderer is mid-reload (harmless,
  resumes); MediaPipe losing the body in poor light (features go stale — consider a
  hold/decay); feedback module climbing if `ceiling` is too high.

See [`CONTRIBUTING.md`](../CONTRIBUTING.md) for the step-by-step runbook and the
troubleshooting checklist.
