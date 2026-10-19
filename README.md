# vdisplay

Tiny CLI that creates a `CGVirtualDisplay` — a real "extra monitor" that
exists only in software — and keeps it alive while the process runs.

Built by reverse-engineering how BetterDisplay creates dummy displays:
`CGVirtualDisplayDescriptor` → `CGVirtualDisplay initWithDescriptor:` →
`CGVirtualDisplayMode` → `CGVirtualDisplaySettings` → `applySettings:`.
Private API — local tooling only, not App Store–safe.

## Usage

```sh
make            # builds ./vdisplay
./vdisplay      # 1920×1080, default
./vdisplay 2560 1440
```

While running, the display shows up in System Settings → Displays and is
addressable by `screencapture -D<n>` / ScreenCaptureKit like a real one.
Ctrl-C removes it.

Use case: recording app demos — put app windows on the virtual display,
record that display; the user's main session is untouched.
