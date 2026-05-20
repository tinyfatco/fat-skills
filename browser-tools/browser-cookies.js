#!/usr/bin/env node

import { browserRequest, browserSessionRequest, printConfigError, resolveUrl } from "./browser-client.js";

const args = process.argv.slice(2);
const help = args.includes("--help") || args.includes("-h");
const useSession = takeFlag(args, "--session");
const urlArg = args.find((arg) => !arg.startsWith("--"));

if (help) {
	console.log("Usage: browser-cookies.js [url] [--session]");
	console.log("\nPrints document.cookie for the target URL. HttpOnly cookies are not exposed.");
	process.exit(0);
}

try {
	const url = useSession && !urlArg ? undefined : await resolveUrl(urlArg);
	const response = await (useSession ? browserSessionRequest : browserRequest)("evaluate", {
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

function takeFlag(args, flag) {
	const index = args.indexOf(flag);
	if (index === -1) return false;
	args.splice(index, 1);
	return true;
}
