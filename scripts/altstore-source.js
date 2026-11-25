// Writes the source that AltStore, SideStore and stores like them read, with the newest iPhone app of the release, so the app can be added to them and updated from them.
const fs = require("fs");

const repo = process.env.GITHUB_REPOSITORY || "not-akari/sumizuri";
const version = process.env.VERSION;
const code = (process.env.CODE || "").match(/app\.versionCode=(\d+)/)?.[1] || "0";
const ipa = "Sumizuri-ios-unsigned.ipa";
if (!version) throw new Error("the version of the release is missing");
if (!fs.existsSync(ipa)) throw new Error(`${ipa} is missing`);

// The icon of the app as it is in the repo, at full size.
const icon = `https://raw.githubusercontent.com/${repo}/main/iosApp/Sumizuri/Assets.xcassets/AppIcon.appiconset/AppIcon.png`;
// The file of this version, so a store that kept the source a while still gets the file it lists.
const download = `https://github.com/${repo}/releases/download/${version}/${ipa}`;
const about = "Sumizuri is a media viewer for manga, comics, novels and video from sources you add yourself. It comes with no content of its own.";
const date = new Date().toISOString();
const size = fs.statSync(ipa).size;
const notes = `Version ${version}. What changed is on https://github.com/${repo}/releases/tag/${version}`;

const source = {
  name: "Sumizuri",
  identifier: "com.sumizuri.source",
  subtitle: "Media viewer for your own library",
  description: about,
  iconURL: icon,
  website: "https://sumizuri.notakari.com",
  apps: [
    {
      name: "Sumizuri",
      bundleIdentifier: "com.sumizuri.app",
      developerName: "Sumizuri",
      subtitle: "Media viewer for your own library",
      localizedDescription: about,
      iconURL: icon,
      category: "entertainment",
      versions: [{ version, buildVersion: code, date, localizedDescription: notes, downloadURL: download, size, minOSVersion: "15.0" }],
      // The same for stores that read the older form of a source, with the newest version on the app itself.
      version,
      versionDate: date,
      versionDescription: notes,
      downloadURL: download,
      size,
      appPermissions: {
        entitlements: [],
        privacy: {
          NSFaceIDUsageDescription: "Sumizuri uses Face ID to open the app lock.",
          NSPhotoLibraryUsageDescription: "Sumizuri reads a picture you choose, such as one for your profile.",
        },
      },
    },
  ],
  news: [],
};

fs.writeFileSync("Sumizuri-altstore.json", JSON.stringify(source, null, 2) + "\n");
console.log(`the store source lists ${version}, ${size} bytes`);
