import { Array, Record, pipe } from "effect"

/** Transforms plain text into lua key-value tables */
export const CloneKeyToValue = (s: string): string => pipe(
	normalizeLf(s),
	x => x.split("\n"),
	Array.filter(x => x.length > 0),
	Array.filter(x => !x.startsWith("--")),// Comments
	Array.map(warbler),
	luaTableFromEntries,
)

/** Caution: this removes duplicate values. */
export const ReverseLuaHashmap = (s: string): string => pipe(
	normalizeLf(s),
	luaTableToJsRec,
	Record.toEntries,
	Array.map(swap),
	x => [...new Map(x)],// Remove duplicate keys from target locale
	luaTableFromEntries,
)

// https://stackoverflow.com/a/58106002
const luaTableToJsRec = (x: string): Record<string, string> => {
	const json = x
		.trim()
		.replace("return ", "")// drop lua return syntax
		.replace(/\["(.+)\"] = "/g, `"$1": "`)// lua to js key-value syntax
		.replace(/(\,)(?=\s*})/g, "")// trailing commas
		.split("\n")
		.map(x => x.replace(/\s*--.*$/, ""))// strip comments
		.filter(x => x.match(/^\s*$/) === null)// blank lines
		.join("\n")
	return JSON.parse(json)
}

const luaTableFromEntries = (lines: (readonly [string, string])[]) => pipe(
	lines.map(([k, v]) => `\t["${k}"] = "${v}",`),
	lines => lines.join('\n'),
	lines => `return {\n${lines}\n}\n`,
)

const normalizeLf = (s: string) =>
	s.replace(/\r\n/g, "\n")
/** Psi / Over / Ψ = (f, g, x, y) => f(g(x), g(y)) */
const Ψ = <A, B, C>(x: A, y: A, g: (a: A) => B, f: (a: B, b: B) => C): C =>
	f(g(x), g(y))
const swap = <A, B>([a, b]: Readonly<[A, B]>): [B, A] =>
	[b, a]
const warbler = <A>(x: A): [A, A] =>
	[x, x]
