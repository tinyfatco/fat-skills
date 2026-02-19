#!/usr/bin/env node

import { spawn, execSync } from "node:child_process";
import puppeteer from "puppeteer-core";

// Parse arguments
const args = process.argv.slice(2);
const useProfile = args.includes("--profile");
const profileArg = args.find(a => a.startsWith("--profile="));
const profileName = profileArg ? profileArg.split("=")[1] : "Default";
const forceRestart = args.includes("--restart");
const helpFlag = args.includes("--help") || args.includes("-h");

if (helpFlag) {
	console.log(`Usage: browser-start.js [options]

Options:
  --profile          Use your Chrome Default profile (cookies, logins)
  --profile=NAME     Use specific profile by name
  --restart          Kill existing Chrome and restart
  -h, --help         Show this help

Examples:
  browser-start.js                    # Fresh/isolated profile (default)
  browser-start.js --restart          # Force restart with fresh profile
  browser-start.js --profile          # Use your Default Chrome profile
`);
	process.exit(0);
}

const CHROME_PORT = 9222;
const USER_DATA_DIR = `${process.env.HOME}/.cache/browser-tools`;

// Detect Chrome path
function getChromePath() {
	if (process.platform === "darwin") {
		return "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";
	}
	const paths = ["/usr/bin/google-chrome", "/usr/bin/chromium-browser", "/usr/bin/chromium"];
	for (const p of paths) {
		try {
			execSync(`test -x ${p}`, { stdio: "ignore" });
			return p;
		} catch {}
	}
	throw new Error("Chrome/Chromium not found");
}

// Check if Chrome is already running and responsive
async function isChromReady() {
	try {
		const browser = await Promise.race([
			puppeteer.connect({ browserURL: `http://localhost:${CHROME_PORT}`, defaultViewport: null }),
			new Promise((_, reject) => setTimeout(() => reject(new Error("timeout")), 2000)),
		]);
		await browser.disconnect();
		return true;
	} catch {
		return false;
	}
}

// Kill Chrome on our port
function killChrome() {
	try {
		// Only kill chrome using OUR port, not all chrome instances
		execSync(`pkill -f 'chrome.*--remote-debugging-port=${CHROME_PORT}'`, { stdio: "ignore" });
	} catch {}
}

// Main
async function main() {
	// If Chrome is already running and we don't want to restart, just verify
	if (!forceRestart && await isChromReady()) {
		console.log(`✓ Chrome already running on :${CHROME_PORT}`);
		process.exit(0);
	}

	// Kill existing if restarting or if it's hung
	killChrome();
	await new Promise(r => setTimeout(r, 1000));

	// Prepare user data directory
	const userDataDir = useProfile ? `${process.env.HOME}/.config/google-chrome` : USER_DATA_DIR;
	
	if (!useProfile) {
		execSync(`mkdir -p "${USER_DATA_DIR}"`, { stdio: "ignore" });
	}

	// Detect headless environment (no DISPLAY and no macOS)
	const isHeadless = process.platform !== "darwin" && !process.env.DISPLAY;

	// Build Chrome args
	const chromeArgs = [
		`--remote-debugging-port=${CHROME_PORT}`,
		`--user-data-dir=${userDataDir}`,
		"--no-first-run",
		"--no-sandbox",
		"--disable-setuid-sandbox",
		"--disable-background-timer-throttling",
		"--disable-backgrounding-occluded-windows",
		"--disable-gpu",
		"--disable-dev-shm-usage",
	];

	if (isHeadless) {
		chromeArgs.push("--headless");
	}

	if (useProfile) {
		chromeArgs.push(`--profile-directory=${profileName}`);
	}

	// Get DISPLAY for Linux
	const env = { ...process.env };
	if (process.platform === "linux" && !env.DISPLAY) {
		// Try common display values
		for (const display of [":9", ":1", ":0"]) {
			try {
				execSync(`DISPLAY=${display} xdpyinfo`, { stdio: "ignore", timeout: 1000 });
				env.DISPLAY = display;
				break;
			} catch {}
		}
	}

	// Start Chrome
	const chromePath = getChromePath();
	const chrome = spawn(chromePath, chromeArgs, {
		detached: true,
		stdio: "ignore",
		env,
	});
	chrome.unref();

	// Wait for Chrome to be ready
	let ready = false;
	for (let i = 0; i < 30; i++) {
		if (await isChromReady()) {
			ready = true;
			break;
		}
		await new Promise(r => setTimeout(r, 500));
	}

	if (!ready) {
		console.error("✗ Failed to start Chrome");
		console.error("  Try: DISPLAY=:9 browser-start.js --restart");
		process.exit(1);
	}

	const profileInfo = useProfile ? ` (profile: ${profileName})` : " (fresh profile)";
	console.log(`✓ Chrome started on :${CHROME_PORT}${profileInfo}`);
}

main();
