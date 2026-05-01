const fs = require("fs");
const path = require("path");
const { execSync } = require("child_process");

const ROOT = __dirname;
const TOC_FILE = path.join(ROOT, "DyBAddon.toc");
const RELEASE_DIR = path.join(ROOT, "release");
const ADDON_DIR_NAME = "DyB Addon";

// --- Parse TOC file ---
const tocContent = fs.readFileSync(TOC_FILE, "utf8");
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
  // Change into release dir so the zip contains "DyB Addon/..." at the root
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
