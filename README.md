# DMGEKI – disk image · layout · build

🇬🇧 English · [🇭🇺 Magyar](README.hu.md)

![DMGEKI](docs/assets/dmgeki-main.png)

**DMGEKI** is a native macOS app for designing and building `.dmg` installers visually: drop in your app, arrange the Finder window exactly as your users will see it, style the background, and press **Build DMG**.

It's written in Swift / SwiftUI and drives the macOS command-line tools under the hood (`hdiutil`, AppleScript for the Finder window, `tiffutil`, `codesign`, `xcrun notarytool` / `stapler`).

DMGEKI is an **EKIDIO** app. See also: [STEMEKI](https://github.com/Ekidio/stemeki) · [CHORDEKI](https://github.com/Ekidio/chordeki) · [EXEKI](https://github.com/Ekidio/exeki).

## Features

- **WYSIWYG Finder canvas:** a life-size Finder window (540 × 350 pt) with your app, the `/Applications` shortcut and their labels. Drag icons around with live X / Y readout.
- **Snapping:** grid overlay, snap to grid, snap to alignment guides, auto-centre icons vertically, zoom in / out / 100 %.
- **Background:** presets (Modern Gradient, Dark Minimal, Light Minimal, Ocean Blue) or your own image (Fill / Fit / Stretch), auto-resized to a Retina 1080 × 700 px background. Export the rendered background as an image.
- **Colour overlay:** tint the background with any colour and opacity, with quick presets.
- **Watermark hint:** an optional "Drag to Applications to Install" style hint; its text and icon follow the **Icon Font Color**.
- **Icons and labels:** icon size 64–256 pt, label size 10–18 pt, label at the bottom or on the right, label colour with swatches.
- **Drag arrow:** curved, straight, glow gradient, minimal line or none – baked into the background.
- **Volume:** mounted volume name, volume icon (your `.icns` or the app's own icon), output file name and folder.
- **Projects:** **File → Open Project…** (⌘O) and **Save Project…** (⌘S) as `.dmgproj`.
- **Build DMG** (⌘B, top right): builds the image in the background (UDZO by default; ULFO, UDBZ, UDRO, UDRW supported by the engine).
- **DMG Ready:** when the build is done, an animated card shows the file and its size, with **Show in Finder**, **Open DMG** and **Done**.
- **EKI start-up animation:** "DMG" slides in, a disc is burned track by track, the blue drive casing drops over it and locks, and "EKI" is cut out of it – with a mechanical sound (spin-up, head ticks, blocks snapping in, the latch) instead of a jingle. Click to skip.

![DMG Ready](docs/assets/dmgeki-ready.png)

> The build engine also supports code signing (Developer ID), notarization + stapling, a license agreement (EULA) and exporting a standalone `build_dmg.sh` for CI. These are in the code but not yet exposed in the interface.

## Requirements

- macOS 14 Sonoma or later
- Xcode command-line tools (Swift 5.9+)

## Build and run

```bash
./build_app.sh
open DMGEKI.app
```

`build_app.sh` builds a release binary, packages `DMGEKI.app` with its icon, signs it ad-hoc and refreshes the Finder / Dock icon cache.

For development:

```bash
swift run DMGCanvasApp
```

or open `Package.swift` in Xcode and press ⌘R.

## Project layout

```
DMGEKI/
├── Package.swift
├── build_app.sh                       # release build → DMGEKI.app
├── Resources/AppIcon.icns
├── docs/assets/                       # README screenshots
└── Sources/DMGCanvasApp/
    ├── main.swift                     # app entry, menu commands (Open / Save Project)
    ├── Models/                        # project, items, window settings, formats, build log
    ├── Services/
    │   ├── DMGBuilderService.swift    # hdiutil / Finder / signing build engine
    │   ├── CanvasBackgroundRenderer.swift
    │   ├── AppleScriptGenerator.swift
    │   ├── ImageCache.swift           # keeps images off the main thread's hot path
    │   ├── MechanicalSound.swift      # synthesised machine sounds for the animations
    │   └── …
    └── Views/
        ├── MainView.swift             # sidebar · canvas · inspector, toolbar
        ├── Canvas/ Sidebar/ Inspector/ Console/
        └── Components/
            ├── SplashView.swift       # EKI start-up animation
            ├── BuildSuccessView.swift # "DMG Ready" animation
            ├── HexColorWell.swift     # colour well bound to hex (eyedropper-safe)
            └── DMGEKILogoView.swift
```
