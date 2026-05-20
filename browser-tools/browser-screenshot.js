#!/usr/bin/env node

import {
	browserRequest,
	looksLikeUrl,
	outputPathOrDefault,
	printConfigError,
	resolveUrl,
	timestampedPath,
	writeBase64File,
} from "./browser-client.js";

const args = process.argv.slice(2);
const help = args.includes("--help") || args.includes("-h");
const fullPage = takeFlag(args, "--full-page");
const jpeg = takeFlag(args, "--jpeg");
const webp = takeFlag(args, "--webp");
const width = takeNumberOption(args, "--width");
const height = takeNumberOption(args, "--height");
const positional = args.filter((arg) => !arg.startsWith("--"));

if (help) {
	console.log("Usage: browser-screenshot.js [url] [output] [--full-page] [--width N] [--height N] [--jpeg|--webp]");
	console.log("\nCaptures a screenshot with Cloudflare Browser Rendering.");
	process.exit(0);
}

try {
	const urlArg = looksLikeUrl(positional[0]) ? positional.shift() : undefined;
	const url = await resolveUrl(urlArg);
	const type = jpeg ? "jpeg" : webp ? "webp" : "png";
	const response = await browserRequest("screenshot", {
		url,
		fullPage,
		width,
		height,
		type,
	});
	const fallback = timestampedPath("screenshot", response.mimeType);
	const output = outputPathOrDefault(positional[0], fallback);
	await writeBase64File(response.dataBase64, output);
	console.log(output);
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

function takeNumberOption(args, flag) {
	const index = args.indexOf(flag);
	if (index === -1) return undefined;
	const value = Number(args[index + 1]);
	args.splice(index, 2);
	return Number.isFinite(value) ? value : undefined;
}
