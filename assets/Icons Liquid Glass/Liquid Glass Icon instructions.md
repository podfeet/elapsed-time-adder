## The process

1. **Split your source art into layers** — right now your `assets/icon geometry/` folder has flat PNGs and one Affinity file (`elapsed_time_icon.af`). For Icon Composer you need the background (gradient/plate) and the stopwatch symbol as **separate** flat assets with no baked shadows/gradients/transparency effects — those get applied *by* Icon Composer instead. Looks like `elapsed_time_icon_stopwatch no alpha.png` may already be a separable foreground piece — worth checking in Affinity whether background and stopwatch are on distinct layers you can export individually at 1024×1024.
2. **Open Icon Composer** — it's bundled with your Xcode: `Xcode → Open Developer Tool → Icon Composer` (or Spotlight "Icon Composer"). This is a GUI design tool — I can't drive it for you, this part is on you.
3. **Build the layered icon** — import the background, add the stopwatch as a foreground layer (up to 4 allowed), and set material/blend properties per layer. Icon Composer has a live preview for Light, Dark, Tinted, and Clear appearances plus the new OS 27 refraction look — check legibility and contrast in all of them, especially Dark/Tinted since your icon has fine linework.
4. **Export a `.icon` file** and drop it into the Xcode project (alongside or replacing `AppIcon.appiconset`).
5. **Point the target at it** — in Xcode, target → General → App Icons and Launch Images, set the App Icon Source to the new `.icon` file. Xcode compiles it into `Assets.car` for OS 26/27 and auto-generates a backward-compatible fallback for older OS versions, so you don't lose support for users on earlier iOS/macOS.
6. **Build and check yourself** (per our usual rule — I won't run `xcodebuild`) — look at it in Simulator, including toggling the Home Screen icon appearance (Light/Dark/Tinted) in Settings.

Once you've got the `.icon` file in hand and want help wiring step 5 into the Xcode project settings, or updating `CLAUDE.md` with the new setup, I can do that part.

Sources: [MacRumors — iOS 27 Revamps App Icons](https://www.macrumors.com/2026/06/16/ios-27-revamps-app-icons/), [Create with Swift — Crafting Liquid Glass app icons with Icon Composer](https://www.createwithswift.com/crafting-liquid-glass-app-icons-with-icon-composer/), [Cult of Mac — Liquid Glass changes in iOS 27 and macOS 27](https://www.cultofmac.com/news/liquid-glass-changes-ios-27-macos-27)



In my .af file I have everything as separate elements. I could make the stop watch on one layer and the plus/minus on another and the background on a third. Or I could have separate layers for the circle, the push pin on the top and the sweep area.

Both are valid; Icon Composer supports 1 background + up to 4 foreground layers, so the granular option (circle, pin, sweep, background) plus plus/minus fits exactly at the max. Here's how I'd think about which split earns its keep — the cost of an extra layer isn't zero: **each foreground layer gets its own specular edge highlight and glass bevel from Icon Composer**, traced around that layer's silhouette. So the real question per element isn't "can I split it out" but "does this thing sit at a genuinely different visual depth, or benefit from an independently-tinted material?" Splitting things that are actually coplanar just adds visible seams/rims where none should be.

Going through your elements:

- **Background (plate/gradient)** — own layer, always. Non-negotiable, that's the base.
- **Circle (watch case/face)** — own foreground layer. This is the primary shape sitting above the background plate; it's the one place a glass bevel reads correctly as "the edge of the watch."
- **Push pin (crown at top)** — own foreground layer, and I'd put real weight behind splitting this one out. On a physical stopwatch the crown genuinely stands proud of the case — giving it independent depth is exactly the kind of thing Liquid Glass layering is *for*, and it'll catch a specular highlight that visually pops in a way a flat icon can't. This is the highest-value split of the bunch.
- **Sweep area (the elapsed arc on the face)** — I'd lean toward keeping this **merged into the circle/face layer** rather than splitting it out. It's flush with the dial, not raised, so a separate glass edge around its arc shape risks reading as a floating disc cut into the face rather than a marking on it. The exception: if you want the sweep to carry its own tint (e.g., a colored glass arc distinct from a neutral metal face) — that's worth the seam risk, but test it in Icon Composer's preview before committing, since you won't know if it looks like a marking vs. a floating ring until you see it rendered with the actual bevel.
- **Plus/minus badge** — own layer, topmost in the stack. This is the element that actually communicates what your app does, so it should read as sitting above everything else, closest to the viewer.

So my recommendation: **4 layers, not 5** — background, circle+sweep (merged), pin, plus/minus. That uses 3 of your 4 available foreground slots, leaves the sweep flat where it belongs, and spends the "extra depth" budget on the one element (the pin) that actually has physical justification for standing apart.

Practical export notes for Affinity:

- Export each layer as its own PNG at 1024×1024 on the **full canvas** (not cropped to the shape's bounding box) so everything aligns when Icon Composer stacks them.
- Transparent background, no baked drop shadows/gradiated bevels on any layer — Icon Composer applies its own lighting/material per layer, and baked-in shading will double up or fight with it.
- Stacking order in Icon Composer should match depth: background → circle/face → pin → plus/minus (topmost).

Once you've exported the layers, the next step is importing them into Icon Composer and previewing across Light/Dark/Tinted — that's a good checkpoint to come back to me if you want help wiring the resulting `.icon` file into the Xcode project.