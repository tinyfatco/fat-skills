#!/usr/bin/env node

import { browserRequest, looksLikeUrl, outputPathOrDefault, printConfigError, resolveUrl, writeBase64File } from "./browser-client.js";
import { join } from "node:path";
import { tmpdir } from "node:os";

const args = process.argv.slice(2);
const help = args.includes("--help") || args.includes("-h");
const positional = args.filter((arg) => !arg.startsWith("--"));

if (help) {
	console.log("Usage: browser-pdf.js [url] [output.pdf]");
	console.log("\nRenders a public URL to PDF with Cloudflare Browser Rendering.");
	process.exit(0);
}

try {
	const urlArg = looksLikeUrl(positional[0]) ? positional.shift() : undefined;
	const url = await resolveUrl(urlArg);
	const response = await browserRequest("pdf", { url });
	const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
	const fallback = join(tmpdir(), `page-${timestamp}.pdf`);
	const output = outputPathOrDefault(positional[0], fallback);
	await writeBase64File(response.dataBase64, output);
	console.log(output);
} catch (err) {
	if (!printConfigError(err)) console.error(`Error: ${err instanceof Error ? err.message : String(err)}`);
	process.exit(1);
}
