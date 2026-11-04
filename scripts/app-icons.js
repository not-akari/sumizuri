// Makes the Android launcher icons for every mix of background, book and ring the icon editor offers, and their manifest entries. Run it from the root of the repo with node scripts/app-icons.js, and keep its tables in step with the icon parts in the shared AppIcons.kt.
const fs = require("fs");
const path = require("path");

const nl = "\r\n";
const res = path.join("app", "android", "src", "main", "res");
const manifest = path.join("app", "android", "src", "main", "AndroidManifest.xml");

const backs = {
  Ink: "#0F1114",
  Paper: "#EDE6D6",
  Sakura: "#E7A3B6",
  Indigo: "#2E3170",
  Matcha: "#6F8F55",
  Night: "#1A1D24",
};
const books = {
  Classic: { disc: "#1A1D24", left: "#F4F1E4", right: "#D9D6CA", spine: "#BEBBAF", lines: "#B8B5A9", edgeDark: "#8E8A7E", edgeLight: "#B4B0A2" },
  Mono: { disc: "#141414", left: "#FFFFFF", right: "#D4D4D4", spine: "#B0B0B0", lines: "#9A9A9A", edgeDark: "#5E5E5E", edgeLight: "#9A9A9A" },
  Moon: { disc: "#E8E0B0", left: "#1A1D24", right: "#2C303A", spine: "#3C414D", lines: "#5D6473", edgeDark: "#0F1114", edgeLight: "#3C414D" },
  Gold: { disc: "#0F1114", left: "#F4F1E4", right: "#D9D6CA", spine: "#BEBBAF", lines: "#C79A4A", edgeDark: "#8E8A7E", edgeLight: "#B4B0A2" },
};
const rings = { Cream: "#E8E0B0", Gold: "#D9A441", White: "#FFFFFF", None: null };

// The five icons of earlier versions keep their names and their own files, so a pick made then still works.
const old = { Ink: "ic_launcher", Paper: "ic_launcher_paper", Sakura: "ic_launcher_sakura", Indigo: "ic_launcher_indigo", Matcha: "ic_launcher_matcha" };
const isOld = (back, book, ring) => book === "Classic" && ring === "Cream" && back !== "Night";
const entryName = (back, book, ring) => (isOld(back, book, ring) ? `Icon${back}` : `Icon${back}${book}${ring}`);
const iconName = (back, book, ring) => (isOld(back, book, ring) ? old[back] : `ic_launcher_${back}_${book}_${ring}`.toLowerCase());
const artName = (book, ring) => `ic_launcher_art_${book}_${ring}`.toLowerCase();

const band = (d) => `M128,230 L128,${235 + d} Q167.5,${220.5 + d} 216,${242 + d} Q250,${216 + d} 306,${225 + d} L306,220 Z`;
const lines = [
  [132, 181, 159, 169.5, 198, 186], [132, 194, 158, 182, 198, 200], [133, 208, 158, 196.5, 200, 213],
  [226, 184, 250, 166, 280, 173], [230, 198, 252, 180, 280, 186], [232, 212, 254, 194, 288, 199],
].map(([a, b, c, d, e, f]) => `M${a},${b} Q${c},${d} ${e},${f}`).join(" ");
const fill = (color, data) => `    <path android:fillColor="${color}" android:pathData="${data}"/>`;
const stroke = (color, width, data, round) =>
  `    <path android:strokeColor="${color}" android:strokeWidth="${width}"${round ? ' android:strokeLineCap="round"' : ""} android:pathData="${data}"/>`;

function write(file, rows) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, rows.join(nl) + nl);
}

// The book and its ring on the 108 wide grid of an adaptive icon, from the same shapes as the icon inside the app.
for (const [book, c] of Object.entries(books)) {
  for (const [ring, ringColor] of Object.entries(rings)) {
    write(path.join(res, "drawable", `${artName(book, ring)}.xml`), [
      `<?xml version="1.0" encoding="utf-8"?>`,
      `<!-- Made by scripts/app-icons.js. -->`,
      `<vector xmlns:android="http://schemas.android.com/apk/res/android"`,
      `    android:width="108dp"`,
      `    android:height="108dp"`,
      `    android:viewportWidth="432"`,
      `    android:viewportHeight="432">`,
      fill(c.disc, "M106.5,215.5 A109,109 0 1 1 324.5,215.5 A109,109 0 1 1 106.5,215.5 Z"),
      ...(ringColor ? [stroke(ringColor, 17, "M178.2,104.1 A117.5,117.5 0 1 1 128.9,136.1", true)] : []),
      fill(c.edgeDark, band(22)),
      fill(c.edgeLight, band(13)),
      fill(c.left, "M120,167 Q166.5,140.5 214,172 L214,242 Q167.5,220.5 121,235 Z"),
      fill(c.right, "M215,170 Q263,136.5 311,159 L311,225 Q250,216 216,242 Z"),
      stroke(c.spine, 3, "M215,171 L215,242", false),
      stroke(c.lines, 5.5, lines, true),
      `</vector>`,
    ]);
  }
}

// Each new mix as an adaptive icon, and for Android 7, which has none, the round icon of its background with the usual book.
const colors = [`<?xml version="1.0" encoding="utf-8"?>`, `<!-- Made by scripts/app-icons.js. -->`, `<resources>`];
for (const [back, color] of Object.entries(backs)) colors.push(`    <color name="ic_launcher_back_${back.toLowerCase()}">${color}</color>`);
for (const back of Object.keys(backs)) {
  for (const book of Object.keys(books)) {
    for (const ring of Object.keys(rings)) {
      if (isOld(back, book, ring)) continue;
      const name = iconName(back, book, ring);
      write(path.join(res, "mipmap-anydpi-v26", `${name}.xml`), [
        `<?xml version="1.0" encoding="utf-8"?>`,
        `<!-- Made by scripts/app-icons.js. -->`,
        `<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">`,
        `    <background android:drawable="@color/ic_launcher_back_${back.toLowerCase()}"/>`,
        `    <foreground android:drawable="@drawable/${artName(book, ring)}"/>`,
        `    <monochrome android:drawable="@mipmap/ic_launcher_monochrome"/>`,
        `</adaptive-icon>`,
      ]);
      colors.push(`    <item name="${name}" type="mipmap">@mipmap/${old[back] ?? old.Ink}</item>`);
    }
  }
}
colors.push(`</resources>`);
write(path.join(res, "values", "ic_launcher_icons.xml"), colors);

// One entry in the launcher for each mix, of which only the usual one is on until another is picked.
const start = "<!-- The app in the launcher, one entry for each icon. Made by scripts/app-icons.js. -->";
const end = "<!-- End of the launcher entries. -->";
let text = fs.readFileSync(manifest, "utf8");
const from = text.indexOf(start);
const to = text.indexOf(end);
if (from < 0 || to < 0) throw new Error("the manifest has lost the marks around the launcher entries");
const entries = [];
for (const back of Object.keys(backs)) {
  for (const book of Object.keys(books)) {
    for (const ring of Object.keys(rings)) {
      const icon = iconName(back, book, ring);
      entries.push(
        `        <activity-alias`,
        `                android:name=".${entryName(back, book, ring)}"`,
        `                android:targetActivity=".MainActivity"`,
        `                android:icon="@mipmap/${icon}"`,
        `                android:roundIcon="@mipmap/${icon}"`,
        `                android:enabled="${back === "Ink" && book === "Classic" && ring === "Cream"}"`,
        `                android:exported="true">`,
        `            <intent-filter>`,
        `                <action android:name="android.intent.action.MAIN"/>`,
        `                <category android:name="android.intent.category.LAUNCHER"/>`,
        `            </intent-filter>`,
        `            <meta-data android:name="android.app.shortcuts" android:resource="@xml/shortcuts" />`,
        `        </activity-alias>`,
      );
    }
  }
}
text = text.slice(0, from) + start + nl + entries.join(nl) + nl + "        " + text.slice(to);
fs.writeFileSync(manifest, text);
console.log(`wrote ${entries.length / 13} launcher entries`);
