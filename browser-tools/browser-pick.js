#!/usr/bin/env node

if (process.argv.includes("--help") || process.argv.includes("-h")) {
	console.log("Usage: browser-pick.js 'instruction'");
}

console.error("browser-pick.js is not supported by the stateless remote browser tools yet.");
console.error("Use browser-content.js, browser-screenshot.js, or browser-eval.js to inspect page structure.");
process.exit(2);
