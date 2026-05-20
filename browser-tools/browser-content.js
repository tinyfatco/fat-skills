#!/usr/bin/env node

import { browserRequest, printConfigError, resolveUrl } from "./browser-client.js";

const args = process.argv.slice(2);
const includeHtml = takeFlag(args, "--html");
const help = args.includes("--help") || args.includes("-h");
const urlArg = args.find((arg) => !arg.startsWith("--"));

if (help || !urlArg) {
	console.log("Usage: browser-content.js <url> [--html]");
	console.log("\nExtracts visible page text and links with Cloudflare Browser Rendering.");
	process.exit(urlArg ? 0 : 1);
}

try {
	const url = await resolveUrl(urlArg);
	const page = await browserRequest("content", { url, includeHtml });
	console.log(`URL: ${page.url}`);
	if (page.title) console.log(`Title: ${page.title}`);
	console.log("");
	console.log(page.text || "(No visible text)");
	if (Array.isArray(page.links) && page.links.length > 0) {
		console.log("\nLinks:");
		for (const link of page.links.slice(0, 30)) {
			const label = link.text ? `${link.text} - ` : "";
			console.log(`- ${label}${link.href}`);
		}
	}
	if (includeHtml && page.html) {
		console.log("\nHTML:");
		console.log(page.html);
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
