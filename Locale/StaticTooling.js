// Inputs plain text, ex:
// sample text line one
// sample \n two
//
// and outputs a lua key-value table:
// return {
//    ["sample text line one"]=["sample text line one"],
//    ["sample \n two"]=["sample \n two"],
// }
export const CloneKeyToValue = (contents) => {
	const lines = contents
		.split("\n")
		.filter(x => x.length > 0)
		.filter(x => !x.startsWith("--"))// Comments
		.map(warbler)
	return tuplesToTable(lines)
}

export const ReverseLuaHashmap = (fileContents) => {
	const hashmap = luaToJson(fileContents)
	const reversed = Object.entries(hashmap).map(swap)
	const lines = [...new Map(reversed)]// Remove duplicate keys from target locale
	return tuplesToTable(lines)
}

// https://stackoverflow.com/a/58106002
const luaToJson = (fileContents) => {
	const _START = "return "
	if (!fileContents.startsWith(_START))
		throw new Error("Invalid export format")
	const json = fileContents
		.replace(_START, "")// drop lua return syntax
		.replace(/\["(.+)\"] = "/g, `"$1": "`)// lua to js key-value syntax
		.replace(/(\,)(?=\s*})/g, "")// trailing commas
		.split("\n")
		.map(x => x.replace(/\s*-- .+$/, ""))// strip comments
		.filter(x => x.match(/^\s*$/) === null)// blank lines
		.join("\n")
	return JSON.parse(json)
}

const tuplesToTable = tuples => {
	const lines = tuples.map(([k, v]) => `\t["${k}"] = "${v}",\n`)
	return `return {\n${lines.join("")}}\n`
}

const swap = ([a, b]) => [b, a]
const warbler = x => [x, x]
