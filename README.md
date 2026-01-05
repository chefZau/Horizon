# Horizon — Sun Phases Widget (iOS / WidgetKit)

A lightweight iOS home-screen widget that visualizes key sun/photography phases (sunrise/sunset + golden hour + blue hour) with a minimal “horizon” design.

> Built with SwiftUI + WidgetKit using an `AppIntentTimelineProvider`.

## Why this project exists

I’m a photography hobbyist, and the most magical light is the hour before/after sunrise and sunset. Those are the moments when the sun angle is perfect and the scene comes alive. This widget keeps that sweet spot front and center—no math, no guessing—so I know exactly when to head out and shoot.

## What it shows

- **Phase label** (e.g. Sunrise / Golden Hour / Sunset / Blue Hour…)
- **Countdown to next boundary** (e.g. “49m 30s”)
- **Sunrise / Sunset time** (HH:mm)
- A phase-themed gradient background + horizon band/highlight
- Phase gallery (see screenshots below)

<table>
  <tr>
    <td align="center">
      <img src="docs/screenshots/phase-sunrise.png" width="200" alt="Sunrise phase" /><br/>
      <sub>Sunrise — Neutral to harsh daylight</sub>
    </td>
    <td align="center">
      <img src="docs/screenshots/phase-golden.png" width="200" alt="Golden hour" /><br/>
      <sub>Golden Hour — Warm, directional light</sub>
    </td>
    <td align="center">
      <img src="docs/screenshots/phase-sunset.png" width="200" alt="Sunset phase" /><br/>
      <sub>Sunset — Deep orange/amber</sub>
    </td>
  </tr>
  <tr>
    <td align="center">
      <img src="docs/screenshots/phase-blue-start.png" width="200" alt="Blue hour start" /><br/>
      <sub>Blue Hour Start — Warm red → deep brown band</sub>
    </td>
    <td align="center">
      <img src="docs/screenshots/phase-blue.png" width="200" alt="Blue hour remaining" /><br/>
      <sub>Blue Hour — Pink-to-purple sky, deep purple ground</sub>
    </td>
    <td align="center">
      <img src="docs/screenshots/phase-night.png" width="200" alt="Night phase" /><br/>
      <sub>Night — Dark navy with subtle blue glow</sub>
    </td>
  </tr>
</table>

> The current implementation splits **Blue hour** into *start* and *remaining* to better match real photography decision points.


## Project status

✅ UI prototype completed  
✅ Real astronomical time–driven timeline implemented  
✅ Phase transitions validated against system Weather app  
✅ Medium-size widget (systemMedium) only (small removed)

## Project structure

Key files:

- `Shared/SunDataService.swift`  
  Shared astronomy + phase resolution + formatting used by both app and widget.

- `HorizonWidget.swift`  
  Widget configuration, timeline provider, entries, previews (systemMedium).

- `HorizonArcShape.swift` / `HorizonFillShape.swift`  
  Horizon geometry for the highlight arc and filled ground band.

- `SunWidgetModel.swift` & `SunWidgetView.swift`  
  View model and SwiftUI layout (full-bleed gradient, horizon band, typography).

- `SunTheme.swift`  
  Per-phase visual themes (gradients/colors).

- `TodayView.swift` / `LocationView.swift` / `AboutView.swift`  
  Main app surfaces for today’s phase/times, location info, and about copy.

- `AppGroupStore.swift` / `LocationManager.swift`  
  App Group data access and location write-back (lat/lon/timestamp/timeZoneId/city) with widget reload.


## Phase logic (current)

The widget timeline is driven by real astronomical times and switches phases at these boundaries:

- Today **sunrise**
- **Golden hour start**
- **Sunset**
- **Blue hour start** → **Blue hour remaining** (midpoint split)
- **Blue hour end**
- Next day **sunrise**

The countdown always points to the *next upcoming boundary*.

Phase resolution (pseudo-code)
```swift
if now < sunrise            -> preDawn
else if now < goldenStart   -> daytime
else if now < sunset        -> sunset
else if now in blueStart...blueEnd:
    if now < midpoint(blueStart, blueEnd) -> blueHourStart
    else                                   -> blueHourRemaining
else                        -> night
```

Notes:
- A newly generated timeline uses “today” + “next day sunrise.” After midnight, phase remains `night` until the next timeline is generated and `now < sunrise` holds (then `preDawn` shows). 

### Phase interpretation

Phases are **time ranges**, not single instants.

- `sunrise` represents the low-sun transition period after the official sunrise time.
- `daytime` begins only after this transition stabilizes.
- `goldenHourStart` is tied to **sunset**, not morning.
- Phase changes always occur at real astronomical boundaries.

This model favors **visual continuity** over strict clock-based labels, matching how daylight is perceived in practice.

## Getting started

1. Open `Horizon.xcodeproj` in Xcode  
2. Select the **HorizonWidgetExtension** scheme  
3. Run on an iOS Simulator  
4. Add the widget to the Home Screen (systemMedium)

### Preview

The project includes `#Preview(as: .systemMedium)` samples covering all phases via preview entries in `HorizonWidget.swift`.

## Configuration

Data flow (app ↔︎ widget):
- Main app gets device location, reverse-geocodes a `timeZoneId`, and writes `latitude`, `longitude`, `timestamp`, `timeZoneId` (and city) to the App Group `group.com.lucazhou.horizon`, then reloads widget timelines.
- Widget reads the same App Group values; if missing or older than 12h, it falls back to Toronto coords/timezone.
- Both app and widget call the same `SunDataService.computeSunState(...)`, using the stored timezone for **both** astronomy math and `DateFormatter` output, keeping times/phase in sync.

## Design goals

- Clean, card-less widget surface (full-bleed background)
- Phase-based color language inspired by Apple Weather
- Minimal but expressive horizon visualization
- Accurate time math with strict UTC → local conversion discipline
- Split blue hour into start/remaining to match photography use cases

## Next steps

- Use real device location (privacy-aware)
- AppIntent-based location selection
- Support multiple widget sizes
- Optional Live Activity / Lock Screen variant
- Fine-tune gradients & highlight intensity

## Notes

Widgets have limited execution time. Timeline entries are generated only at meaningful astronomical boundaries to preserve system performance.

## License

This project is released under the MIT License.
Design and visual concepts are inspired by Apple Weather.
