import { promises as Fs } from "fs"
import * as Process from "process"

// Generating ordered locale files:
// 1. manually regex the English into raw text and other langs into js objects
//    \["([a-zA-Z0-9 \-():']+)"\] = true,
// 2. sort English
// 3. map over English, lookup other lang by key, and output lua

// Generating reverse maps:
// 1. parse lua table to js array of tuples
// 2. Pair.Swap
// 3. serialize js to lua table

const sortWithoutThe = ts => {
	const psi = (f, g) => (x, y) => f(g(x), g(y))
	const stripThe = x => x.startsWith("The ") ? x.slice(4) : x
	return ts.toSorted(psi((a,b) => a.localeCompare(b), stripThe))
}

const toLuaWithFallback = (english, localeJs) => {
	const lines = english
		.split("\n")
		.filter(x => x.length > 0)
		.map(k => {
			const v = localeJs[k] ?? null
			if (!v) console.warn("Miss: " + k)
			return [k, v]
		})
		.map(([k,v]) => v == null
			? `\t["${k}"] = "${k}",-- TODO translate\n`
			: `\t["${k}"] = "${v}",\n`
		)
	return "return {\n" + lines.join("") + "}\n"
}

const dir = Process.cwd() + "/"
const xs = await Fs.readFile(dir + "enUS/Spellbook.text", { encoding: "utf8" })

// const text = toLuaWithFallback(xs, Cn)
// // const text = sortWithoutThe(xs.split("\n")).join("\n")

// await Fs.writeFile(dir + "temp", text, { flag: "w" })
