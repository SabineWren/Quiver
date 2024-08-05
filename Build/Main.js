import { promises as Fs } from "fs"
import { bundle } from "luabundle"
import * as Process from "process"
import { ThrottleF } from "./Throttle.js"
import { Result } from "./Result.js"

const isWatch = Process.argv.includes("--lua-watch")
const dirSource = Process.cwd()

const predOutputFile = (filename) =>
	filename.endsWith(".bundle.lua")

const output = Result
	.OfNullable(
		"Missing output flag.\nUsage: --output=filename.lua",
		Process.argv.find(x => x.startsWith("--output=")),
	)
	.Map(x => x.replace("--output=", ""))
	.Bind(x => predOutputFile(x)
		? Result.Ok(x)
		: Result.Error(["-- Invalid bundle name:", x, "-- Must end with:", ".bundle.lua"].join("\n"))
	)
	.Match({
		Ok: v => v,
		Error: (cause) => {
			console.error(cause)
			Process.exit(1)
		}
	})

// Colored text in terminal:
// https://stackoverflow.com/a/41407246
const colorize = text => "\x1b[33m" + text + "\x1b[0m"

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
	console.log(`${colorize(msgTime)}ms -- ${output} [${event}] ${msgSource}`)
}

await runBundler("Startup")

if (isWatch) {
	const throttle = ThrottleF(10)
	// https://bun.sh/guides/read-file/watch
	const watcher = Fs.watch(dirSource, { recursive: true })
	for await (const w of watcher) {
		const { eventType, filename } = w
		void await Result
			.OfNullable("", filename)// Why is it nullable?
			.Filter("", x => !predOutputFile(x))// Don't watch output
			.Filter("", x => x.match(/.+\.lua$/))// Only watch possible imports
			.Match({
				Ok: v => throttle(() => runBundler(eventType, v)),
				Error: _cause => Promise.resolve(),
			})
	}
}
