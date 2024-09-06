import { promises as Fs } from "fs"
import { bundle } from "luabundle"
import * as Process from "process"
import { ThrottleF } from "./Throttle.js"
import { Result } from "./Result.js"
import { WarblerKeyValue } from "../Locale/StaticTooling.js"

const isWatch = Process.argv.includes("--lua-watch")
const dirSource = Process.cwd()
const _OUTPUT_EXTENSION = ".bundle.lua"
const _ENGLISH_SOURCE = "enUS.translations.text"
const _ENGLISH_OUT = "enUS.translations.lua"

const output = Result
	.OfNullable(Process.argv.find(x => x.startsWith("--output=")))
	.MapError(_ => "Missing output flag.\nUsage: --output=filename.lua")
	.Map(x => x.replace("--output=", ""))
	.Filter(
		x => x.endsWith(_OUTPUT_EXTENSION),
		x => ["-- Invalid bundle name:", x, "-- Must end with:", _OUTPUT_EXTENSION].join("\n"),
	)
	.GetSome(cause => {
		console.error(cause)
		return Process.exit(1)
	})

const makeEnglishTranslations = async () => {
	const dir = dirSource + "/Locale/"
	const x = await Fs.readFile(dir + _ENGLISH_SOURCE, { encoding: "utf8" })
	const y = WarblerKeyValue(x)
	await Fs.writeFile(dir + _ENGLISH_OUT, y, { flag: "w" })
	console.log(`locale -- ${_ENGLISH_OUT}`)
}

const runBundler = async (event, source) => {
	const tStart = performance.now()
	// https://github.com/Benjamin-Dobell/luabundle
	const bundledLua = bundle("Main.lua", {
		isolate: true,
		luaVersion: 5.1,
		metadata: false,// un-bundling requires true
		// paths: ["./?"] Doesn't work? Use resolveModule instead.
		// (name: string, packagePaths: readonly string[]) => string | null
		resolveModule: (name, _packagePaths) => "./" + name,
	})

	await Fs.writeFile(output, bundledLua, { flag: "w" })
	const msgTime = (performance.now() - tStart).toFixed(0).padStart(3, " ")
	const msgSource = source ? `<-- ${source}` : ""
	// Colored text in terminal:
	// https://stackoverflow.com/a/41407246
	const colorize = text => "\x1b[33m" + text + "\x1b[0m"
	console.log(`${colorize(msgTime)}ms -- ${output} [${event}] ${msgSource}`)
}

await makeEnglishTranslations()
await runBundler("Startup")

const throttleEnglish = ThrottleF(50)
const throttleCode = ThrottleF(50)

const rebuildEnglish = (eventType, filename) =>
	throttleEnglish(async () => {
		await makeEnglishTranslations()
		await rebuildCode(eventType, filename)
	})
const rebuildCode = (eventType, filename) =>
	throttleCode(() => runBundler(eventType, filename))

if (isWatch) {
	// Loops asynchronously forever
	// https://bun.sh/guides/read-file/watch
	const watcher = Fs.watch(dirSource, { recursive: true })
	for await (const w of watcher) {
		const { eventType, filename } = w
		const _ = await Result
			.OfNullable(filename)
			.Filter(
				x => !x.endsWith(_OUTPUT_EXTENSION),
				_ => "Ignoring output bundle",
			)
			.Filter(
				x => !x.match(/.+\.d\.lua$/),
				_ => "Ignoring type definitions",
			)
			.Bind(x => {
				if (x.endsWith(_ENGLISH_SOURCE))
					return Result.Ok(rebuildEnglish(eventType, x))
				else if (x.match(/.+\.lua$/))
					return Result.Ok(rebuildCode(eventType, x))
				else
					return Result.Error("Expected .lua or .translations.text")
			})
			.Default(Promise.resolve())
	}
}
