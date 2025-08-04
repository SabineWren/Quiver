/** Transforms plain text into lua key-value tables
@example
// Input:
sample text line one
sample \n two
// Output:
return {
	["sample text line one"]=["sample text line one"],
	["sample \n two"]=["sample \n two"],
}
*/
export const CloneKeyToValue = (contents: string) => {
	const lines = contents
		.replace(/\r\n/g, "\n")// normalize line endings first
		.split("\n")
		.filter(x => x.length > 0)
		.filter(x => !x.startsWith("--"))// Comments
		.map(warbler)
	return tuplesToLuaTable(lines)
}

export const ReverseLuaHashmap = (fileContents: string) => {
	const hashmap = luaToJson(fileContents)
	const reversed = Object.entries(hashmap).map(swap)
	const lines = [...new Map(reversed)]// Remove duplicate keys from target locale
	return tuplesToLuaTable(lines)
}

// https://stackoverflow.com/a/58106002
const luaToJson = (fileContents: string) => {
	const _START = "return "
	if (!fileContents.startsWith(_START))
		throw new Error("Invalid export format")
	const json = fileContents
		.replace(/\r\n/g, "\n")// normalize line endings
		.replace(_START, "")// drop lua return syntax
		.replace(/\["(.+)\"] = "/g, `"$1": "`)// lua to js key-value syntax
		.replace(/(\,)(?=\s*})/g, "")// trailing commas
		.split("\n")
		.map(x => x.replace(/\s*--.*$/, ""))// strip comments
		.filter(x => x.match(/^\s*$/) === null)// blank lines
		.join("\n")
	return JSON.parse(json) as Record<string, string>
}

const tuplesToLuaTable = (tuples: (readonly [string, string])[]) => {
	const lines = tuples.map(([k, v]) => {
		// Escape special characters in strings (input should already be clean of line endings)
		const escapedKey = k.replace(/\\/g, '\\\\').replace(/"/g, '\\"')
		const escapedValue = v.replace(/\\/g, '\\\\').replace(/"/g, '\\"')
		return `\t["${escapedKey}"] = "${escapedValue}",`
	})
	return `return {\n${lines.join('\n')}\n}\n`
}

const swap = <A, B>([a, b]: Readonly<[A, B]>) => [b, a] as const
const warbler = <A>(x: A) => [x, x] as const
