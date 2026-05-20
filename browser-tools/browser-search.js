#!/usr/bin/env node

import { browserRequest, printConfigError } from "./browser-client.js";

const args = process.argv.slice(2);
const help = args.includes("--help") || args.includes("-h");
const fetchContent = takeFlag(args, "--content");
const numResults = takeNumberOption(args, "-n") || 5;
const query = args.filter((arg) => !arg.startsWith("--")).join(" ").trim();

if (help || !query) {
	console.log("Usage: browser-search.js <query> [-n <num>] [--content]");
	console.log("\nRuns a lightweight DuckDuckGo search in Cloudflare Browser Rendering.");
	process.exit(query ? 0 : 1);
}

try {
	const url = `https://duckduckgo.com/html/?q=${encodeURIComponent(query)}`;
	const expression = `(() => Array.from(document.querySelectorAll(".result, .web-result")).slice(0, ${Math.max(1, Math.min(20, numResults))}).map((result) => {
		const link = result.querySelector("a.result__a, a[href]");
		const snippet = result.querySelector(".result__snippet");
		return {
			title: (link?.textContent || "").trim().replace(/\\s+/g, " "),
			link: link?.href || "",
			snippet: (snippet?.textContent || "").trim().replace(/\\s+/g, " ")
		};
	}).filter((item) => item.title && item.link))()`;
	const response = await browserRequest("evaluate", { url, expression });
	const results = Array.isArray(response.result) ? response.result.slice(0, numResults) : [];

	if (results.length === 0) {
		console.log("No results found");
		process.exit(0);
	}

	for (let i = 0; i < results.length; i++) {
		const result = results[i];
		console.log(`--- Result ${i + 1} ---`);
		console.log(`Title: ${result.title}`);
		console.log(`URL: ${result.link}`);
		if (result.snippet) console.log(`Snippet: ${result.snippet}`);
		if (fetchContent) {
			try {
				const page = await browserRequest("content", { url: result.link });
				console.log("\nContent:");
				console.log(String(page.text || "").slice(0, 4000));
			} catch (err) {
				console.log(`\nContent: (error fetching: ${err instanceof Error ? err.message : String(err)})`);
			}
		}
		if (i < results.length - 1) console.log("");
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

function takeNumberOption(args, flag) {
	const index = args.indexOf(flag);
	if (index === -1) return undefined;
	const value = Number(args[index + 1]);
	args.splice(index, 2);
	return Number.isFinite(value) ? value : undefined;
}
