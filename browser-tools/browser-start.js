#!/usr/bin/env node

import { getBrowserConfig, printConfigError } from "./browser-client.js";

if (process.argv.includes("--help") || process.argv.includes("-h")) {
	console.log("Usage: browser-start.js");
	console.log("\nChecks that TinyFat remote browser tools are configured.");
	process.exit(0);
}

try {
	const { baseUrl } = getBrowserConfig();
	console.log("Remote browser tools ready");
	console.log(`API: ${baseUrl}`);
	console.log("Chrome runs in Cloudflare Browser Rendering; no local Chrome process is started.");
	console.log("Use browser-session.js start for a stateful tab when a workflow needs continuity.");
} catch (err) {
	if (!printConfigError(err)) console.error(`Error: ${err instanceof Error ? err.message : String(err)}`);
	process.exit(1);
}
