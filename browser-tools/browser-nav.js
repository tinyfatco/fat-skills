#!/usr/bin/env node

import { browserSessionRequest, printConfigError, setActiveUrl } from "./browser-client.js";

const args = process.argv.slice(2).filter((arg) => arg !== "--new");
const useSession = takeFlag(args, "--session");
const url = args[0];

if (!url || process.argv.includes("--help") || process.argv.includes("-h")) {
	console.log("Usage: browser-nav.js <url> [--new] [--session]");
	console.log("\nSets the active URL for subsequent remote browser commands.");
	console.log("\nExamples:");
	console.log("  browser-nav.js https://example.com");
	console.log("  browser-nav.js --session https://example.com/dashboard");
	console.log("  browser-screenshot.js");
	process.exit(url ? 0 : 1);
}

try {
	const active = await setActiveUrl(url);
	if (useSession) {
		const response = await browserSessionRequest("nav", { url: active });
		console.log(`Session browser URL: ${response.activeUrl || active}`);
	} else {
		console.log(`Active browser URL: ${active}`);
	}
} catch (err) {
	if (!printConfigError(err)) console.error(`Error: ${err instanceof Error ? err.message : String(err)}`);
	process.exit(1);
}

function takeFlag(args, flag) {
	const index = args.indexOf(flag);
	if (index === -1) return false;
	args.splice(index, 1);
	return true;
}
