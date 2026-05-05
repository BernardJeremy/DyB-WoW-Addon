const fs = require("fs");
const path = require("path");
const { execSync } = require("child_process");

const ROOT = __dirname;
const TOC_FILE = path.join(ROOT, "DyBAddon.toc");
const RELEASE_DIR = path.join(ROOT, "release");
const ADDON_DIR_NAME = "DyBAddon";

// --- Parse flags and arguments ---
const args = process.argv.slice(2);
const buildOnly = args.includes("--build");
const newVersion = args.find((a) => !a.startsWith("--"));

// Read TOC file (always needed)
const tocContentRaw = fs.readFileSync(TOC_FILE, "utf8");
const currentVersionMatch = tocContentRaw.match(/^## Version:\s*([^\r\n]+)/m);
const currentVersion = currentVersionMatch ? currentVersionMatch[1].trim() : "(unknown)";

if (!buildOnly) {
  // --- Require version argument ---
  if (!newVersion) {
    console.error(`ERROR: Missing required argument: new version.`);
    console.error(`       Current addon version: ${currentVersion}`);
    console.error(`       Usage: node release.js <new-version>`);
    console.error(`              node release.js --build          (use current TOC version, skip git)`);
    process.exit(1);
  }

  // --- Update version in TOC file ---
  const updatedTocContent = tocContentRaw.replace(
    /^(## Version:\s*)[^\r\n]+/m,
    `$1${newVersion}`
  );
  fs.writeFileSync(TOC_FILE, updatedTocContent, "utf8");
  console.log(`Updated TOC version: ${currentVersion} -> ${newVersion}`);

  // --- Git commit the updated TOC ---
  try {
    execSync(`git -C "${ROOT}" add "${TOC_FILE}"`);
    execSync(`git -C "${ROOT}" commit -m "chores: bump version to v${newVersion}"`);
    console.log(`Git commit: chores: bump version to v${newVersion}`);
  } catch (err) {
    console.error("ERROR: Git commit failed.");
    console.error(err.message);
    process.exit(1);
  }
} else {
  console.log(`Build-only mode: skipping TOC update and git commit.`);
  console.log(`Using current TOC version: ${currentVersion}`);
}

// --- Parse TOC file ---
const tocContent = buildOnly ? tocContentRaw : fs.readFileSync(TOC_FILE, "utf8");
const tocLines = tocContent.split(/\r?\n/);

let version = null;
const luaFiles = [];

for (const line of tocLines) {
  const trimmed = line.trim();

  if (trimmed.startsWith("## Version:")) {
    version = trimmed.replace("## Version:", "").trim();
    continue;
  }

  // Non-empty lines not starting with ## are file entries
  if (trimmed.length > 0 && !trimmed.startsWith("#")) {
    luaFiles.push(trimmed);
  }
}

if (!version) {
  console.error("ERROR: Could not find ## Version in the TOC file.");
  process.exit(1);
}

console.log(`Version   : ${version}`);
console.log(`Lua files : ${luaFiles.join(", ")}`);

// --- Prepare release directory ---
const stagingDir = path.join(RELEASE_DIR, ADDON_DIR_NAME);

if (fs.existsSync(RELEASE_DIR)) {
  fs.rmSync(RELEASE_DIR, { recursive: true, force: true });
}
fs.mkdirSync(stagingDir, { recursive: true });

// --- Copy files into staging dir ---
const filesToInclude = [
  "DyBAddon.toc",
  "dyb_logo.png",
  ...luaFiles,
];

for (const file of filesToInclude) {
  const src = path.join(ROOT, file);
  const dest = path.join(stagingDir, file);

  if (!fs.existsSync(src)) {
    console.warn(`WARNING: File not found, skipping: ${file}`);
    continue;
  }

  fs.copyFileSync(src, dest);
}

// --- Write VERSION file ---
fs.writeFileSync(path.join(RELEASE_DIR, "VERSION"), version, "utf8");

// --- Create ZIP ---
const zipName = `DyBAddon-v${version}.zip`;
const zipPath = path.join(RELEASE_DIR, zipName);

// Use the zip CLI (available on macOS/Linux) or PowerShell on Windows
try {
  // Change into release dir so the zip contains "DyBAddon/..." at the root
  execSync(`cd "${RELEASE_DIR}" && zip -r "${zipName}" "${ADDON_DIR_NAME}"`);
} catch {
  // Fallback: PowerShell (Windows without zip)
  try {
    execSync(
      `powershell -Command "Compress-Archive -Path '${stagingDir}' -DestinationPath '${zipPath}' -Force"`
    );
  } catch (err) {
    console.error("ERROR: Could not create ZIP. Install 'zip' or run on Windows with PowerShell.");
    console.error(err.message);
    process.exit(1);
  }
}

// --- Clean up staging directory ---
fs.rmSync(stagingDir, { recursive: true, force: true });

console.log(`\nRelease created:`);
console.log(`  release/VERSION       -> ${version}`);
console.log(`  release/${zipName}`);
console.log(`    └── ${ADDON_DIR_NAME}/`);
for (const file of filesToInclude) {
  console.log(`         ├── ${file}`);
}
