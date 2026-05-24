# App Store Submittal Notes

## Name & Bundle ID

Bundle ID: com.podfeet.ElapsedTimeAdder

![Image on 2026-05-04 07.17.11 PM](app-store-submittal-images/new-app-submit-name-bundleid.png)

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



## Validate build

error:

Invalid large app icon. The large app icon in the asset catalog in “ElapsedTimeAdder.app” can’t be transparent or contain an alpha channel. For details, visit: https://developer.apple.com/design/human-interface-guidelines/app-icons.

Opened icon in Preview, unchecked alpha. then ran this command to recreate the icon sizes:



```
SRC="/Users/allison/htdocs/elapsed-time-adder/assets/ElapsedTimeAdderIcon.png"
DEST="/Users/allison/htdocs/elapsed-time-adder/ElapsedTimeAdder/ElapsedTimeAdder/Assets.xcassets/AppIcon.appiconset"

sips -z 1024 1024 "$SRC" --out "$DEST/AppIcon-1024.png"
sips -z 16 16   "$SRC" --out "$DEST/AppIcon-16.png"
sips -z 32 32   "$SRC" --out "$DEST/AppIcon-16@2x.png"
sips -z 32 32   "$SRC" --out "$DEST/AppIcon-32.png"
sips -z 64 64   "$SRC" --out "$DEST/AppIcon-32@2x.png"
sips -z 128 128 "$SRC" --out "$DEST/AppIcon-128.png"
sips -z 256 256 "$SRC" --out "$DEST/AppIcon-128@2x.png"
sips -z 256 256 "$SRC" --out "$DEST/AppIcon-256.png"
sips -z 512 512 "$SRC" --out "$DEST/AppIcon-256@2x.png"
sips -z 512 512 "$SRC" --out "$DEST/AppIcon-512.png"
sips -z 1024 1024 "$SRC" --out "$DEST/AppIcon-512@2x.png"
```

### Product → Archive

then opens archives and can run validate
