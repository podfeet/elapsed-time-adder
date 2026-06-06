# Test Flight bugs fixed/what to test

## Ways to give feedback in order of preference:

- open an issue at https://github.com/podfeet/elapsed-time-adder
- send me an email at allison@podfeet.com
- least desirable - feedback inside TestFlight. There's no way for me to write back to you or keep track of the ideas.



## Changes & things to test

New Features:

- Added a hide keyboard button to make it easier to get to the add row, export, and reset buttons without scrolling in a reduced window area
- On iOS, changed "a Podfeet App" to be an about button that opens a card giving feedback and other options. On macOS, the card is always expanded 
- Proper Mac app now has a cleaner layout

Fixed/improved in this build:

- CSV AirDrop should now correctly create only one file.
- Screen rotation on Pro Max isn't cut off now
- HH:MM:SS and CSV exports to file with titles `Elapsed Time Adder.txt`  and `Elapsed Time Adder.csv, respectively. 
- Title row is now correctly provided for both CSV and HH:MM:SS exports
- Rows with data but no title entered will be called "Row 1", "Row 2", etc. (instead of just "Row"
- Blank rows are no longer exported, and their row numbers are skipped, so you don't get Row 1, Row 3
- Commas in text entry don't break CSV export. Now compliant with RFC 4180 open standard for CSV.
- Negative values are disallowed in single cells, and a single minus sign without values now also throws an error.
- Explanation of why a spreadsheet is clearer - swapped in "time-of-day" for "absolute" time
- Icons added to buttons to make it a little more obvious what they do
- Lowered minimum requirements to iOS 18.6, macOS 15.6, visionOS 2.6



## New screenshots

At least one:

- **Video** (+9:10)
- **Intro music** (−0:12)
- **Audio offset** (+1:16)

Title: Never do timestamp math in your head again

12M 43S + 7.5M 22S →  20 min 35 sec

12min 43sec  + 7.5min 22sec =20 mins 35 secs 

^^^ this was calculated automatically in Typora!

## Video in App Store

## App Preview video specs

- **Length: 15–30 seconds.** Hard rule, enforced by App Store Connect.
- **Up to 3 previews** per device size (they show *before* your screenshots in the carousel).
- **Format:** `.mov`, `.m4v`, or `.mp4` (H.264 or ProRes), ~**30 fps**.
- **Resolution:** the device's **native screen resolution** — and here's the catch: **no device frame.** Unlike screenshots, an app preview must be the **raw screen content** at native size. If you wrap it in a phone bezel, the dimensions change and ASC rejects it.
- **Must be real in-app footage.** Apple reviews these and rejects pure motion-graphics/marketing that isn't the actual app running.
- **First frame = poster frame** (the still shown before someone hits play) — you can choose which frame.

## How to capture (the reliable way)

The cleanest path that *guarantees* an accepted resolution:

1. **Plug your physical iPhone into the Mac** → open **QuickTime Player** → **File → New Movie Recording** → click the dropdown next to record and **select your iPhone** as the source.
2. Record yourself using the app (calm, deliberate taps — enter a few times, hit a total, export, etc.).
3. Edit in **iMovie / Final Cut** (you have the tools): trim to **15–25s**, add subtle music, maybe text captions for each feature, light zoom-ins. Export at the **native resolution** (don't add borders).

> Simulator screen recordings (`xcrun simctl io booted recordVideo`, or Simulator → File → Record Screen) *can* work if the resolution matches an accepted size, but device-capture via QuickTime is the no-surprises route. For the 6.9" slot specifically, you'd want Pro Max footage — and since you don't own one, the **Pro Max simulator's Record Screen** is your friend there (same trick as your screenshots).

## Where to upload

**App Store Connect → My Apps → [your app] → [the version] → "App Previews and Screenshots"** — same section as screenshots. For each device size, there are **3 preview slots at the front** (before the screenshot slots). Drag the video in; ASC validates length + resolution on upload, then lets you pick the poster frame.

## "Cool kids" tips

- **Lead with your strongest feature in the first 3 seconds** — many people don't watch past that, and the poster frame is your hook.
- **No narration needed** — captions + music read better on autoplay-muted.
- **Keep it to 1–2 features**, not a full tour. For Time Adder: show entering a few rows, the live total updating, then an export. That's the whole story in ~15s.
- **One 6.9" video can serve smaller iPhone sizes** (App Store Connect scales it), so you may only need to make the Pro Max one.