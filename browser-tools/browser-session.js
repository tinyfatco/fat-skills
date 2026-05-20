#!/usr/bin/env node

import {
	browserSessionRequest,
	formatValue,
	printConfigError,
	setActiveUrl,
} from "./browser-client.js";

const args = process.argv.slice(2);
const help = args.includes("--help") || args.includes("-h");
const action = args.find((arg) => !arg.startsWith("--"));
const keepAliveMs = takeNumberOption(args, "--keep-alive-ms");
const url = args.find((arg) => /^https?:\/\//i.test(arg || ""));

if (help || !action || !["start", "status", "close"].includes(action)) {
	console.log("Usage: browser-session.js <start|status|close> [url] [--keep-alive-ms N]");
	console.log("\nManages a stateful remote browser tab for workflows that need continuity.");
	console.log("\nExamples:");
	console.log("  browser-session.js start https://example.com");
	console.log("  browser-nav.js --session https://example.com/dashboard");
	console.log("  browser-eval.js --session 'document.title'");
	console.log("  browser-session.js close");
	process.exit(action ? 0 : 1);
}

try {
	if (action === "start") {
		const response = await browserSessionRequest("start", { url, keepAliveMs });
		if (response.activeUrl) await setActiveUrl(response.activeUrl);
		console.log(`Session browser ready: ${response.sessionId || "(active)"}`);
		if (response.activeUrl) console.log(`Active URL: ${response.activeUrl}`);
		console.log(`Idle timeout: ${Math.round((response.keepAliveMs || keepAliveMs || 300000) / 1000)}s`);
	} else if (action === "status") {
		const response = await browserSessionRequest("status");
		console.log(formatValue(response));
	} else {
		const response = await browserSessionRequest("close");
		console.log(response.closed ? "Session browser closed" : "No active session browser");
	}
} catch (err) {
	if (!printConfigError(err)) console.error(`Error: ${err instanceof Error ? err.message : String(err)}`);
	process.exit(1);
}

function takeNumberOption(args, flag) {
	const index = args.indexOf(flag);
	if (index === -1) return undefined;
	const value = Number(args[index + 1]);
	args.splice(index, 2);
	return Number.isFinite(value) ? value : undefined;
}
