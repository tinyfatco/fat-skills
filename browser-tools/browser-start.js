#!/usr/bin/env node

import { spawn, execSync, spawnSync } from "node:child_process";
import { existsSync } from "node:fs";

const args = process.argv.slice(2);
const forceRestart = args.includes("--restart");

if (args.includes("--help") || args.includes("-h")) {
	console.log("Usage: browser-start.js [--restart]");
	process.exit(0);
}

const PORT = 9222;

function findChrome() {
	if (process.platform === "darwin")
		return "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";
	for (const p of ["/usr/bin/chromium", "/usr/bin/google-chrome", "/usr/bin/chromium-browser"]) {
		if (existsSync(p)) return p;
	}
	throw new Error("Chrome not found");
}

async function isReady() {
	// Direct CDP HTTP probe — puppeteer.connect leaves session state that races
	// on rapid retries. Chrome serves /json/version as soon as the debugger is up.
	try {
		const res = await fetch("http://localhost:" + PORT + "/json/version", {
			signal: AbortSignal.timeout(1500),
		});
		return res.ok;
	} catch { return false; }
}

function displayExists(d) {
	// Check the X11 socket file directly — no xdpyinfo needed
	const num = d.replace(":", "");
	return existsSync("/tmp/.X11-unix/X" + num);
}

function ensureDisplay() {
	// macOS doesn't use X11
	if (process.platform === "darwin") return null;

	// Check if current DISPLAY works
	if (process.env.DISPLAY && displayExists(process.env.DISPLAY)) {
		return process.env.DISPLAY;
	}
	// Probe common displays
	for (const d of [":99", ":9", ":1", ":0"]) {
		if (displayExists(d)) return d;
	}
	// No display found — start Xvfb if available
	try {
		execSync("which Xvfb", { stdio: "ignore" });
		spawn("Xvfb", [":99", "-screen", "0", "1280x1024x24", "-ac"], {
			detached: true, stdio: "ignore"
		}).unref();
		// Wait for socket to appear
		for (let i = 0; i < 10; i++) {
			spawnSync("sleep", ["0.2"]);
			if (displayExists(":99")) return ":99";
		}
	} catch {}
	// Nothing works — headless
	return null;
}

// Already running?
if (!forceRestart && await isReady()) {
	console.log("Chrome already running on :" + PORT);
	process.exit(0);
}

// Kill stale
try {
	execSync("pkill -f 'chrome.*--remote-debugging-port=" + PORT + "'", { stdio: "ignore" });
} catch {}
await new Promise(r => setTimeout(r, 500));

const display = ensureDisplay();
const chromePath = findChrome();
// Chrome thrashes small writes. Keep user-data-dir on local disk, not R2/gocryptfs.
const userDataDir = "/tmp/browser-tools-profile";
execSync("mkdir -p " + JSON.stringify(userDataDir), { stdio: "ignore" });

const chromeArgs = [
	"--remote-debugging-port=" + PORT,
	"--user-data-dir=" + userDataDir,
	"--no-first-run",
	"--no-sandbox",
	"--disable-setuid-sandbox",
	"--disable-background-timer-throttling",
	"--disable-backgrounding-occluded-windows",
	"--disable-gpu",
	"--disable-dev-shm-usage",
];

if (!display) {
	chromeArgs.push("--headless");
	console.log("No display — using headless mode");
} else {
	console.log("Using display " + display);
}

const env = { ...process.env };
if (display) env.DISPLAY = display;

const chrome = spawn(chromePath, chromeArgs, {
	detached: true,
	stdio: ["ignore", "ignore", "pipe"],
	env,
});

let stderr = "";
chrome.stderr.on("data", (d) => {
	stderr += d.toString();
	if (stderr.length > 4000) stderr = stderr.slice(-4000);
});

let exited = false;
let exitInfo = null;
chrome.on("exit", (code, signal) => {
	exited = true;
	exitInfo = { code, signal };
});
chrome.unref();

let ready = false;
for (let i = 0; i < 30; i++) {
	if (exited) break;
	if (await isReady()) { ready = true; break; }
	await new Promise(r => setTimeout(r, 500));
}

if (!ready) {
	console.error("Chrome failed to start");
	console.error("chrome path: " + chromePath);
	console.error("args: " + chromeArgs.join(" "));
	console.error("display: " + (display || "(headless)"));
	if (exitInfo) console.error("exit: code=" + exitInfo.code + " signal=" + exitInfo.signal);
	if (stderr.trim()) console.error("stderr:\n" + stderr.trim());
	else console.error("stderr: (empty)");
	process.exit(1);
}

console.log("Chrome started on :" + PORT + (display ? "" : " (headless)"));
