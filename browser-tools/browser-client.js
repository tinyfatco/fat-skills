import { readFile, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { basename, extname, join } from "node:path";

export const STATE_PATH = join(tmpdir(), "tinyfat-browser-state.json");

export class BrowserConfigError extends Error {}

export function getBrowserConfig() {
	const baseUrl = process.env.TINYFAT_BROWSER_API_URL?.replace(/\/+$/, "");
	const token = process.env.TINYFAT_BROWSER_TOKEN;
	if (!baseUrl || !token) {
		throw new BrowserConfigError(
			"Remote browser tools are not configured. Restart the agent on the latest TinyFat runtime and try again.",
		);
	}
	return { baseUrl, token };
}

export async function browserRequest(action, payload = {}) {
	const { baseUrl, token } = getBrowserConfig();
	const response = await fetch(`${baseUrl}/${action}`, {
		method: "POST",
		headers: {
			Authorization: `Bearer ${token}`,
			"Content-Type": "application/json",
		},
		body: JSON.stringify(payload),
		signal: AbortSignal.timeout(45000),
	});

	let body;
	try {
		body = await response.json();
	} catch {
		body = { error: "invalid_response", error_description: await response.text().catch(() => "") };
	}

	if (!response.ok || body?.ok === false) {
		const message = body?.error_description || body?.error || `${response.status} ${response.statusText}`;
		throw new Error(message);
	}
	return body;
}

export async function browserSessionRequest(action, payload = {}) {
	return browserRequest(`session/${action}`, payload);
}

export async function readState() {
	try {
		return JSON.parse(await readFile(STATE_PATH, "utf8"));
	} catch {
		return {};
	}
}

export async function writeState(next) {
	await writeFile(STATE_PATH, `${JSON.stringify(next, null, 2)}\n`);
}

export async function setActiveUrl(url) {
	const normalized = normalizeUrl(url);
	const state = await readState();
	await writeState({ ...state, activeUrl: normalized, updatedAt: new Date().toISOString() });
	return normalized;
}

export async function getActiveUrl() {
	const state = await readState();
	return state.activeUrl || null;
}

export function normalizeUrl(input) {
	try {
		return new URL(input).toString();
	} catch {
		throw new Error(`Invalid absolute URL: ${input}`);
	}
}

export async function resolveUrl(url) {
	if (url) return normalizeUrl(url);
	const active = await getActiveUrl();
	if (!active) throw new Error("No URL supplied and no active browser URL is set. Run browser-nav.js <url> first.");
	return active;
}

export function formatValue(value) {
	if (value === null || value === undefined) return String(value);
	if (typeof value === "string") return value;
	if (typeof value === "number" || typeof value === "boolean") return String(value);
	return JSON.stringify(value, null, 2);
}

export async function writeBase64File(dataBase64, filepath) {
	await writeFile(filepath, Buffer.from(dataBase64, "base64"));
	return filepath;
}

export function timestampedPath(prefix, mimeType) {
	const ext = mimeType === "image/jpeg" ? "jpg" : mimeType === "image/webp" ? "webp" : "png";
	const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
	return join(tmpdir(), `${prefix}-${timestamp}.${ext}`);
}

export function looksLikeUrl(value) {
	return /^https?:\/\//i.test(value || "");
}

export function outputPathOrDefault(value, fallback) {
	if (!value) return fallback;
	if (looksLikeUrl(value)) return fallback;
	const ext = extname(value);
	return ext ? value : join(value, basename(fallback));
}

export function printConfigError(err) {
	if (err instanceof BrowserConfigError) {
		console.error(`Error: ${err.message}`);
		return true;
	}
	return false;
}
