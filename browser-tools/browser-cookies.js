#!/usr/bin/env node

import { browserRequest, printConfigError, resolveUrl } from "./browser-client.js";

const args = process.argv.slice(2);
const help = args.includes("--help") || args.includes("-h");
const urlArg = args.find((arg) => !arg.startsWith("--"));

if (help) {
	console.log("Usage: browser-cookies.js [url]");
	console.log("\nPrints document.cookie for the target URL. HttpOnly cookies are not exposed.");
	process.exit(0);
}

try {
	const url = await resolveUrl(urlArg);
	const response = await browserRequest("evaluate", {
		url,
		expression: "document.cookie",
	});
	if (!response.result) {
		console.log("(No non-HttpOnly cookies visible to document.cookie)");
	} else {
		for (const cookie of String(response.result).split(";").map((part) => part.trim()).filter(Boolean)) {
			console.log(cookie);
		}
	}
} catch (err) {
	if (!printConfigError(err)) console.error(`Error: ${err instanceof Error ? err.message : String(err)}`);
	process.exit(1);
}
