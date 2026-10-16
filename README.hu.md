# DMGEKI – lemezkép · elrendezés · build

[🇬🇧 English](README.md) · 🇭🇺 Magyar

![DMGEKI](docs/assets/dmgeki-main.png)

A **DMGEKI** natív macOS alkalmazás `.dmg` telepítők vizuális tervezéséhez és elkészítéséhez: behúzod az appodat, pontosan úgy rendezed el a Finder-ablakot, ahogy a felhasználó látni fogja, megformázod a hátteret, és megnyomod a **Build DMG** gombot.

Swift / SwiftUI alatt készült, a háttérben a macOS parancssori eszközeit használja (`hdiutil`, AppleScript a Finder-ablakhoz, `tiffutil`, `codesign`, `xcrun notarytool` / `stapler`).

A DMGEKI egy **EKIDIO** alkalmazás. Lásd még: [STEMEKI](https://github.com/Ekidio/stemeki) · [CHORDEKI](https://github.com/Ekidio/chordeki) · [EXEKI](https://github.com/Ekidio/exeki).

## Funkciók

- **WYSIWYG Finder-vászon:** valós méretű Finder-ablak (540 × 350 pt) az appoddal, az `/Applications` parancsikonnal és a feliratokkal. Az ikonok húzhatók, élő X / Y kijelzéssel.
- **Igazítás:** rácsháttér, rácshoz igazítás, igazítási vezetővonalak, ikonok függőleges középre igazítása, nagyítás / kicsinyítés / 100 %.
- **Háttér:** előre beállított témák (Modern Gradient, Dark Minimal, Light Minimal, Ocean Blue) vagy saját kép (Fill / Fit / Stretch), automatikusan Retina 1080 × 700 px-es háttérré méretezve. A kész háttér képként exportálható.
- **Színátfedés:** a háttér tetszőleges színnel és átlátszósággal színezhető, gyors előbeállításokkal.
- **Watermark felirat:** opcionális „Drag to Applications to Install” jellegű tipp; a szövege és az ikonja az **Icon Font Color** színét követi.
- **Ikonok és feliratok:** ikonméret 64–256 pt, betűméret 10–18 pt, felirat alul vagy jobbra, feliratszín színmintákkal.
- **Húzásjelző nyíl:** íves, egyenes, izzó színátmenetes, minimál vonal vagy nincs – a háttérbe égetve.
- **Kötet:** a felcsatolt kötet neve, kötetikon (saját `.icns` vagy az app saját ikonja), kimeneti fájlnév és mappa.
- **Projektek:** **File → Open Project…** (⌘O) és **Save Project…** (⌘S), `.dmgproj` formátumban.
- **Build DMG** (⌘B, jobb fent): a háttérben elkészíti a lemezképet (alapból UDZO; a motor az ULFO, UDBZ, UDRO, UDRW formátumot is ismeri).
- **DMG kész:** amikor elkészült, egy animált kártya mutatja a fájlt és a méretét, **Show in Finder**, **Open DMG** és **Done** gombokkal.
- **EKI indítóanimáció:** becsúszik a „DMG”, egy lemezre sávonként felkerül az adat, ráereszkedik és bereteszel a kék meghajtóház, majd kivágva megjelenik benne az „EKI” – csilingelés helyett gépies hanggal (motorfelpörgés, fejkattogás, a helyére pattanó blokkok, retesz). Kattintásra átugorható.

![DMG kész](docs/assets/dmgeki-ready.png)

> A build motor kódaláírást (Developer ID), notarizálást és staplinget, licencszerződést (EULA) és önálló `build_dmg.sh` exportot is tud CI-hoz. Ezek a kódban megvannak, de a felületről még nem érhetők el.

## Követelmények

- macOS 14 Sonoma vagy újabb
- Xcode parancssori eszközök (Swift 5.9+)

## Fordítás és futtatás

```bash
./build_app.sh
open DMGEKI.app
```

A `build_app.sh` release binárist fordít, ikonnal együtt `DMGEKI.app`-ba csomagolja, ad-hoc aláírja, és frissíti a Finder / Dock ikongyorsítótárát.

Fejlesztéshez:

```bash
swift run DMGCanvasApp
```

vagy nyisd meg a `Package.swift`-et Xcode-ban, és nyomj ⌘R-t.

## Felépítés

```
DMGEKI/
├── Package.swift
├── build_app.sh                       # release build → DMGEKI.app
├── Resources/AppIcon.icns
├── docs/assets/                       # README képek
└── Sources/DMGCanvasApp/
    ├── main.swift                     # belépési pont, menüparancsok (Open / Save Project)
    ├── Models/                        # projekt, elemek, ablakbeállítások, formátumok, build napló
    ├── Services/
    │   ├── DMGBuilderService.swift    # hdiutil / Finder / aláírás build motor
    │   ├── CanvasBackgroundRenderer.swift
    │   ├── AppleScriptGenerator.swift
    │   ├── ImageCache.swift           # képek gyorsítótára, hogy ne lassuljon a fő szál
    │   ├── MechanicalSound.swift      # szintetizált gépi hangok az animációkhoz
    │   └── …
    └── Views/
        ├── MainView.swift             # oldalsáv · vászon · inspector, eszköztár
        ├── Canvas/ Sidebar/ Inspector/ Console/
        └── Components/
            ├── SplashView.swift       # EKI indítóanimáció
            ├── BuildSuccessView.swift # „DMG kész” animáció
            ├── HexColorWell.swift     # hex kódhoz kötött színválasztó (pipettabiztos)
            └── DMGEKILogoView.swift
```
