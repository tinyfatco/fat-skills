#!/usr/bin/env node

import { printConfigError, setActiveUrl } from "./browser-client.js";

const args = process.argv.slice(2).filter((arg) => arg !== "--new");
const url = args[0];

if (!url || process.argv.includes("--help") || process.argv.includes("-h")) {
	console.log("Usage: browser-nav.js <url> [--new]");
	console.log("\nSets the active URL for subsequent remote browser commands.");
	console.log("\nExamples:");
	console.log("  browser-nav.js https://example.com");
	console.log("  browser-screenshot.js");
	process.exit(url ? 0 : 1);
}

try {
	const active = await setActiveUrl(url);
	console.log(`Active browser URL: ${active}`);
} catch (err) {
	if (!printConfigError(err)) console.error(`Error: ${err instanceof Error ? err.message : String(err)}`);
	process.exit(1);
}
