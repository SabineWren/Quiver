import { promises as Fs } from "fs"
import { bundle } from "luabundle"
import * as Process from "process"
import { ThrottleF } from "./Throttle.js"
import { Result } from "./Result.js"

const isWatch = Process.argv.includes("--lua-watch")
const dirSource = Process.cwd()
const _BUNDLE_GLOB_EXTENSION = ".bundle.lua"

const output = Result
	.OfNullable(Process.argv.find(x => x.startsWith("--output=")))
	.MapError(_ => "Missing output flag.\nUsage: --output=filename.lua")
	.Map(x => x.replace("--output=", ""))
	.Filter(
		x => x.endsWith(_BUNDLE_GLOB_EXTENSION),
		x => ["-- Invalid bundle name:", x, "-- Must end with:", ".bundle.lua"].join("\n"),
	)
	.GetSome(cause => {
		console.error(cause)
		return Process.exit(1)
	})

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

await runBundler("Startup")

if (isWatch) {
	const throttle = ThrottleF(50)
	// Loops asynchronously forever
	// https://bun.sh/guides/read-file/watch
	const watcher = Fs.watch(dirSource, { recursive: true })
	for await (const w of watcher) {
		const { eventType, filename } = w
		void await Result
			.OfNullable(filename)
			.Filter(
				x => !x.endsWith(_BUNDLE_GLOB_EXTENSION),
				_ => "Ignoring output bundle",
			)
			.Filter(
				x => x.match(/.+\.lua$/),
				_ => "Ignoring non-Lua file",
			)
			.Filter(
				x => !x.match(/.+\.d\.lua$/),
				_ => "Ignoring type definitions",
			)
			.Match({
				Ok: v => throttle(() => runBundler(eventType, v)),
				Error: _cause => Promise.resolve(),
			})
	}
}
