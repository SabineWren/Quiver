// Inputs plain text, ex:
// sample text line one
// sample \n two
//
// and outputs a lua key-value table:
// return {
//    ["sample text line one"]=["sample text line one"],
//    ["sample \n two"]=["sample \n two"],
// }
export const WarblerKeyValue = (contents) => {
	const lines = contents
		.trim()
		.split("\n")
		.map(x => `"${x}"`)
		.map(x => `\t[${x}]=${x},\n`)
	return "return {\n" + lines.join("") + "}\n"
}
