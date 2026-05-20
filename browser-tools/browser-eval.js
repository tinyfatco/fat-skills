#!/usr/bin/env node

import { browserRequest, browserSessionRequest, formatValue, getActiveUrl, normalizeUrl, printConfigError } from "./browser-client.js";

const args = process.argv.slice(2);
const help = args.includes("--help") || args.includes("-h");
const useSession = takeFlag(args, "--session");
const url = takeOption(args, "--url");
const expression = args.join(" ").trim();

if (help || !expression) {
	console.log("Usage: browser-eval.js [--url <url>] [--session] 'expression'");
	console.log("\nRuns JavaScript in a remote browser page. Uses the active URL from browser-nav.js when available.");
	console.log("\nExamples:");
	console.log('  browser-eval.js --url https://example.com "document.title"');
	console.log('  browser-eval.js --session "document.title"');
	console.log('  browser-eval.js "document.querySelectorAll(\\\"a\\\").length"');
	process.exit(expression ? 0 : 1);
}

try {
	const activeUrl = url ? normalizeUrl(url) : useSession ? null : await getActiveUrl();
	const response = await (useSession ? browserSessionRequest : browserRequest)("evaluate", {
		url: activeUrl || undefined,
		expression,
	});
	console.log(formatValue(response.result));
} catch (err) {
	if (!printConfigError(err)) console.error(`Error: ${err instanceof Error ? err.message : String(err)}`);
	process.exit(1);
}

function takeOption(args, flag) {
	const index = args.indexOf(flag);
	if (index === -1) return undefined;
	const value = args[index + 1];
	args.splice(index, 2);
	return value;
}

function takeFlag(args, flag) {
	const index = args.indexOf(flag);
	if (index === -1) return false;
	args.splice(index, 1);
	return true;
}
