# vdisplay

A menubar app that gives your Mac a real "extra monitor" — created entirely
in software via Apple's private `CGVirtualDisplay` API. No hardware, no
drivers, no dummy adapter. Display lives while the app runs; Quit removes it.

Pattern adapted from Chromium's `virtual_display_util_mac.mm` (BSD-3) and
KhaosT's CGVirtualDisplay headers.

## Use cases

- Record app demos on a dedicated screen — `screencapture -D2`,
  ScreenCaptureKit, or `ffmpeg -f avfoundation -i "2:none"` captures it while
  your real display stays private.
- Park reference windows on a second screen without owning a monitor.
- Test multi-monitor layouts.

## Build & run

```sh
make            # builds Build/vdisplay.app
make run        # build + open
make clean
```

Or drag `Build/vdisplay.app` into /Applications and launch normally.

## What you get

- Menubar item (display icon) — click to see status / Quit (⌘Q)
- One virtual display, 1920×1080 @ 60Hz, non-HiDPI
- Shows up in System Settings → Displays like a real monitor
- Ctrl-C/quitting the app instantly removes the display; any windows on it
  fall back to the main screen

## Requirements

macOS 14+, Apple Silicon. Private API — works on current macOS 26/27 builds,
may break with future updates.
