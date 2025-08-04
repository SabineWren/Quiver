import * as assert from "node:assert"
import { describe, it } from "node:test"
import { CloneKeyToValue, ReverseLuaHashmap } from "./LuaJsInterop.math.ts"

await describe("Lua JS Interop", async () => {
	await it("Clone English to dictionary", () => {
		const text = `
sample text line one
sample \\n two
`
		const lua = `
return {
	["sample text line one"] = "sample text line one",
	["sample \\n two"] = "sample \\n two",
}
`
		assert.strictEqual(CloneKeyToValue(text).trim(), lua.trim())
	})

	await it("Locale reverse-map", () => {
		const forward = `
return {
	["duplicate text one"] = "hello",
	["duplicate text two"] = "hello",
	["unique text"] = "world",
	["mirrored"] = "mirrored",
}`
		const reverse = `
return {
	["hello"] = "duplicate text two",
	["world"] = "unique text",
	["mirrored"] = "mirrored",
}`
		assert.strictEqual(ReverseLuaHashmap(forward).trim(), reverse.trim())
	})
})
