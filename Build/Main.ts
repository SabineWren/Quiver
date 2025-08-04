import { promises as Fs, type WatchEventType } from "fs"
import { bundle } from "luabundle"
import * as Path from "path"
import * as Process from "process"
import { ThrottleF } from "./Throttle.ts"
import { Result } from "./Result.ts"
import { CloneKeyToValue, ReverseLuaHashmap } from "../Locale/LuaJsInterop.math.ts"
import { Array, flow, Option, pipe } from "effect"

const isWatch = Process.argv.includes("--lua-watch")
const dirSource = Process.cwd()
const _OUTPUT_EXT = ".bundle.lua"
const _ENGLISH_EXT_IN = ".enUS.text"
const _ENGLISH_EXT_OUT = ".enUS.lua"

const bundleName = pipe(
	Array.findFirst(Process.argv, x => x.startsWith("--output=")),
	Result.fromOption,
	Result.mapError(_ => "Missing output flag.\nUsage: --output=filename.lua"),
	Result.map(x => x.replace("--output=", "")),
	Result.Filter(
		x => x.endsWith(_OUTPUT_EXT),
		x => ["-- Invalid bundle name:", x, "-- Must end with:", _OUTPUT_EXT].join("\n"),
	),
	Result.getOrElse(cause => {
		console.error(cause)
		return Process.exit(1)
	}),
)

const makeEnglishTranslations = async (partialPath: string) => {
	const dir = dirSource + "/" + Path.dirname(partialPath) + "/"
	const filenameIn = Path.basename(partialPath)
	const filenameOut = filenameIn.replace(_ENGLISH_EXT_IN, _ENGLISH_EXT_OUT)
	const [pathIn, pathOut] = [filenameIn, filenameOut].map(x => dir + x)
	const x = await Fs.readFile(pathIn, { encoding: "utf8" })
	const y = CloneKeyToValue(x)
	await Fs.writeFile(pathOut, y, { flag: "w" })
	console.log(`locale -- ${filenameIn} -> ${filenameOut}`)
}

const reverseHashmap = async (partialPath: string) => {
	const dir = dirSource + "/" + Path.dirname(partialPath) + "/"
	const filenameIn = Path.basename(partialPath)
	const ext = filenameIn.split(".").slice(1).join(".")
	const filenameOut = filenameIn.replace(ext, "reverse." + ext)
	const [pathIn, pathOut] = [filenameIn, filenameOut].map(x => dir + x)
	const x = await Fs.readFile(pathIn, { encoding: "utf8" })
	const y = ReverseLuaHashmap(x)
	await Fs.writeFile(pathOut, y, { flag: "w" })
	console.log(`locale -- ${filenameIn} -> ${filenameOut}`)
}

const runBundler = async (event: string, source?: string) => {
	const tStart = performance.now()
	// https://github.com/Benjamin-Dobell/luabundle
	const bundledLua = bundle("Main.lua", {
		isolate: true,
		luaVersion: "5.1",
		metadata: false,// un-bundling requires true
		// paths: ["./?"] Doesn't work? Use resolveModule instead.
		// (name: string, packagePaths: readonly string[]) => string | null
		resolveModule: (name, _packagePaths) => "./" + name,
	})

	await Fs.writeFile(bundleName, bundledLua, { flag: "w" })
	const msgTime = (performance.now() - tStart).toFixed(0).padStart(3, " ")
	const msgSource = source ? `<-- ${source}` : ""
	// Colored text in terminal:
	// https://stackoverflow.com/a/41407246
	const colorize = (text: string) => "\x1b[33m" + text + "\x1b[0m"
	console.log(`${colorize(msgTime)}ms -- ${bundleName} [${event}] ${msgSource}`)
}

await Promise.all([
	makeEnglishTranslations("Locale/enUS/Spell.enUS.text"),
	makeEnglishTranslations("Locale/enUS/Translations.enUS.text"),
	makeEnglishTranslations("Locale/enUS/Zone.enUS.text"),
	reverseHashmap("Locale/zhCN/Spell.zhCN.lua"),
	// reverseHashmap("Locale/zhCN/Zone.zhCN.lua"), Not used by Quiver
])
await runBundler("Startup")

const throttleEnglish = ThrottleF(50)
const throttleCode = ThrottleF(50)

const rebuildEnglish = (eventType: WatchEventType, filename: string) =>
	throttleEnglish(async () => {
		await makeEnglishTranslations(filename)
		await rebuildCode(eventType, filename)
	})
const rebuildCode = (eventType: WatchEventType, filename: string) =>
	throttleCode(() => runBundler(eventType, filename))

if (isWatch) {
	// Loops asynchronously forever
	// https://bun.sh/guides/read-file/watch
	const watcher = Fs.watch(dirSource, { recursive: true })
	for await (const w of watcher) {
		const { eventType, filename } = w

		const _ = await pipe(
			Option.fromNullable(filename),
			Result.fromOption,
			Result.Filter(
				x => !x.endsWith(_OUTPUT_EXT),
				_ => "Ignoring output bundle",
			),
			Result.Filter(
				x => !x.match(/.+\.d\.lua$/),
				_ => "Ignoring type definitions",
			),
			Result.flatMap(x => {
				if (x.endsWith(_ENGLISH_EXT_IN))
					return Result.Ok(rebuildEnglish(eventType, x))
				else if (x.match(/.+\.lua$/))
					return Result.Ok(rebuildCode(eventType, x))
				else
					return Result.Error(`Expected .lua or ${_ENGLISH_EXT_IN}`)
			}),
			Result.getOrElse(_ => Promise.resolve())
		)
	}
}
