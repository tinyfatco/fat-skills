#!/usr/bin/env node

import { browserRequest, browserSessionRequest, looksLikeUrl, outputPathOrDefault, printConfigError, resolveUrl, writeBase64File } from "./browser-client.js";
import { join } from "node:path";
import { tmpdir } from "node:os";

const args = process.argv.slice(2);
const help = args.includes("--help") || args.includes("-h");
const useSession = takeFlag(args, "--session");
let htmlPath = takeValueFlag(args, "--html-file") || takeValueFlag(args, "--html-path") || takeValueFlag(args, "--workspace-html");
const positional = args.filter((arg) => !arg.startsWith("--"));

if (help) {
	console.log("Usage: browser-pdf.js [url|html-file] [output.pdf] [--html-file path] [--session]");
	console.log("\nRenders a public URL or workspace HTML file to PDF with Cloudflare Browser Rendering.");
	process.exit(0);
}

try {
	if (!htmlPath && looksLikeHtmlPath(positional[0])) {
		htmlPath = positional.shift();
	}
	if (htmlPath && useSession) {
		throw new Error("--html-file is not supported with --session; render workspace HTML with the stateless PDF command.");
	}

	let response;
	if (htmlPath) {
		response = await browserRequest("pdf", { htmlPath: normalizeWorkspaceHtmlPath(htmlPath) });
	} else {
		const urlArg = looksLikeUrl(positional[0]) ? positional.shift() : undefined;
		const url = useSession && !urlArg ? undefined : await resolveUrl(urlArg);
		response = await (useSession ? browserSessionRequest : browserRequest)("pdf", { url });
	}
	const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
	const fallback = join(tmpdir(), `page-${timestamp}.pdf`);
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

function takeValueFlag(args, flag) {
	const index = args.indexOf(flag);
	if (index === -1) return null;
	const value = args[index + 1];
	if (!value || value.startsWith("--")) {
		throw new Error(`${flag} requires a path`);
	}
	args.splice(index, 2);
	return value;
}

function looksLikeHtmlPath(value) {
	if (!value || looksLikeUrl(value)) return false;
	const clean = value.split(/[?#]/, 1)[0].toLowerCase();
	return clean.endsWith(".html") || clean.endsWith(".htm");
}

function normalizeWorkspaceHtmlPath(value) {
	let path = String(value || "").trim();
	if (!path) throw new Error("HTML path is required");
	if (path === "/data") throw new Error("HTML path must point to a file under /data");
	if (path.startsWith("/data/")) path = path.slice("/data/".length);
	while (path.startsWith("./")) path = path.slice(2);
	return path;
}
