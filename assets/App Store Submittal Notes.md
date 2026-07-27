# App Store Submittal Notes

## Name & Bundle ID

Bundle ID: com.podfeet.ElapsedTimeAdder

![Image on 2026-05-04 07.17.11 PM](app-store-submittal-images/new-app-submit-name-bundleid.png)

## Text

### Promotional Text

> Promotional text lets you inform your App Store visitors of any current app features without requiring an updated submission. This text will appear above your description on the App Store for customers with devices running ios 11 or later, and macos 10.13 or later.

Finally, a calculator that understands elapsed time. Add splits, segments, and durations on iPhone, iPad, and Mac. Spreadsheets can't do this — we can.

### Description

> A description of your app, detailing features and functionality.

Elapsed Time Adder runs on iOS, iPadOS, and macOS to help you add and subtract elapsed time. 

You might ask why not just use a spreadsheet for this? Sadly, while spreadsheets are great at doing calculations, they don't know how to work with elapsed time, only absolute time. Try adding 23 hours plus 7 hours in a spreadsheet — you won't get 30,  you'll get 6 (AM)!

If you need to add split times for running or walking, or keep track of time segments in audio or video recording, or time spent on projects, all of these efforts work great with ElapsedTimeAdder.

Enter the times in each row, along with an optional title for each row, and watch the total update automatically in a plain-language way (e.g., "1 hr 23 min 45 sec").

You can type 384.6 seconds, or 74 minutes, and Elapsed Time Adder will easily work with it. If you want to subtract a row, simply hit the +/- toggle, and you'll see the row turn from green to pink.

Use the "Add Another Row" button to have more rows in your calculations. If you're on a Mac or an iPad with a keyboard, hitting Tab at the end of the last second cell will add a new row too.

Want to start over? Use the Reset button, and you'll be back to the default number of rows, and they'll all be empty.

When you're finished, you can export your data to a CSV suitable for opening in a spreadsheet application, or you can get it in HH:MM:SS format along with the titles for each row. This will take you to the share sheet to send your output where you desire. Note that nothing is stored in a back-end system or in the cloud; all of your data is kept on-device only.

## Keywords

> Include one or more keywords that describe your app. Keywords make App Store search results more accurate. Separate keywords with an English comma, Chinese comma, or a mix of both.

Claude says 100 characters max - this is 100 characters

time,time math,elapsed time calculator,add time,subtract time,split time,workout times,time segments

## Marketing and Support URLs

**Claude's suggestion:**

- **Marketing URL**: GitHub Pages with a custom subdomain (`timeadder.podfeet.com`) — looks professional, free, easy to update
- **Support URL**: A page on that same GitHub Pages site with a brief FAQ and your contact email — solves the "need a GitHub account" problem while keeping everything in one place

That way both URLs live on GitHub Pages, you don't have to touch your WordPress site at all, and you have one tidy place to maintain app info. You could even mention it on your podcast since it's a clean URL.

To create the subdomain timeadder.podfeet.com:

**Step 1: Create the DNS record in DigitalOcean**

1. Log into DigitalOcean → Networking → Domains
2. Find `podfeet.com`
3. Add a new record:
   - Type: `CNAME`
   - Hostname: `timeadder`
   - Value: `yourgithubusername.github.io.` (note the trailing dot)
4. Save it

**Step 2: Configure GitHub Pages to use your custom domain**

1. In your GitHub repo for the Pages site, go to Settings → Pages
2. Under "Custom domain" enter `timeadder.podfeet.com`
3. Save — GitHub will add a `CNAME` file to your repo automatically
4. Check "Enforce HTTPS" once the DNS propagates (can take a few minutes to a few hours)

**That's it** — no nginx config needed since the traffic goes straight to GitHub's servers, not your DigitalOcean droplet.



### Product → Archive

Opens the archives and can run validate, send to App Store



## Process to upload a new build

**In Xcode:**

1. Bump the **Build number** (select the project → target → General → Identity — increment the Build field, e.g. 3 → 4). Version number only needs to change if you're doing a new release.
2. Set the destination to **Any iOS Device (arm64)** — not a simulator
3. **Product → Archive** — this builds a release archive (takes a minute)
4. The **Organizer** window opens automatically showing your archive
5. Click **Distribute App**
6. Choose **TestFlight & App Store** → **Next**
7. Keep defaults and click through until it uploads — Xcode handles the signing and submission

**In App Store Connect (appstoreconnect.apple.com):**

1. Go to your app → **TestFlight** tab
2. The new build will appear (may take a few minutes to process, you'll get an email when ready)
3. If it's your first time with a new build, Apple may ask you to fill in an **Export Compliance** question (just answer No to encryption if you're not using any custom encryption)
4. Once processed, click the build and add it to your test group to make it available to testers

# Screenshots

from Claude code:

### Suggested scenes (in priority order):

1. **The core use case** — a few rows filled in with real-looking data (podcast segment times, commute times, something relatable), showing the plain-English total at the top. This is your hero shot and should be first.
2. **Mix of add and subtract** — show the +/− toggle in action, with some rows green and some red. Demonstrates the killer feature immediately.
3. **The export sheet** — share sheet open showing AirDrop, Mail, etc. Shows it's not just a calculator, you can do something with the result.
4. **iPad/Mac wide layout** — the split view with sidebar looks really polished and shows it's a proper multiplatform app.
5. **The About sheet** — shows the Podfeet branding and feedback links, adds personality.

**For the overlay text, something like:**

- "Add and subtract times in seconds"
- "Mix additions and subtractions"
- "Copy as CSV or HH:MM:SS"
- "Works on iPhone, iPad, Mac and visionOS"

**Final decisions**

- Add & Subtract Complex Times
- 

### Size of screenshots

For App Store screenshots, the required pixel dimensions vary by device:

**iPhone (required):**

- 6.9" display: **1320 × 2868** (iPhone 16 Pro Max) — this is the one Apple requires and it scales down to cover other iPhone sizes

**iPad (required if you support iPad):**

- 13" display:  **2752 x 2064** — covers all iPad sizes 

**Mac (required if you support Mac):**

- Minimum **1280 × 800**, but can be up to **2560 × 1600** — aspect ratio is landscape **16:10**

So iPhone and iPad are both portrait (tall), Mac is landscape (wide). You'll need different compositions for Mac vs iPhone/iPad since the orientation flips.

### Number of screenshots

You can upload up to **10 screenshots per device size**. Apple just requires a minimum of 1. More is generally better since each one is a chance to highlight a different feature before someone decides whether to download.

### Process to take screenshots

1. **Boot the right simulator** — iPhone 17 Pro Max (this falls in Apple's "6.9-inch display" class, so it renders at the exact 1320 × 2868 required).
2. **Get the app into the state you want** (data entered, +/− mix, whatever scene from your list) in the Simulator window.
3. **File → Save Screen** in the Simulator app menu bar (or press **⌘S**). This is the key step — it saves the screenshot at the simulator's **true device pixel resolution**, not the scaled size of the window on your monitor. Screenshotting the window itself (e.g. with macOS's own ⌘⇧4) would capture the wrong resolution.
4. The PNG lands on your **Desktop** by default, named something like `Simulator Screenshot - iPhone 17 Pro Max - <date> at <time>.png` (matches the filenames already deleted from your `assets/app-store-submittal-images/` folder — that's clearly your prior workflow).
   1. Hazel rule moves screenshot to '/Users/allison/htdocs/elapsed-time-adder/assets/app-store-submittal-images/Working image files copy/01 Unframed'
5. Repeat for the iPad Pro 13" simulator and for iPhone 17e, one screenshot per scene.
6. For Mac, since there's no simulator, you'd run the actual app and use ⌘⇧4 (or ⌘⇧5) to capture the app window itself at native resolution, then crop/scale into the 16:10 landscape range.

## Example shown in screenshots

iPhone 17 Pro Max, iPhone 17e

Total s/b: 1 hr 26 min 39 sec

```Recording 1:23:45 (add) : "Intro/Outro" — 0:05:00 (add) : "Dead air" - 0:02:30 (subtract)
Recording    1:23:45
Intro/Outro  0:05:17
Dead air     0:02:23 (subtract)
```

iPad only, Landscape, showing "why not use a spreadsheet?"

Total s/b 1 hr 29 min 59 sec

```
Recording    1:23:45
Intro	       0:02:09
Outro        0:03:08
Dead air     0:02:23 (subtract)
Promo        0:03:20
```

## Process

1. Take screenshot
2. Save in `01 Unframed`
3. Frame screenshot with Shareshot
4. Save in `02 Framed`
5. Import to Affinity in appropriate document
6. Size on import
   1. iPhone Pro Max: 1998x3408 pixels @ 250dpi (86%)
7. Decide on words
8. Export to `03 Framed gradient titled`size 1320x2868

## Completed iPhone 17 Pro screenshots

1. Image down: Add & Subtract Complex Times
2. Image up: Copy CSV
3. Image down: Edit Rows
4. Image up: Get Help

## Completed 13" iPad screenshots

5. iPad 13" 10 rows
6. iPad 13" absurd times
