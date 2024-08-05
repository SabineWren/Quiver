import { promises as Fs } from "fs"
import { bundle } from "luabundle"
import * as Process from "process"
import { ThrottleF } from "./Throttle.js"

const isWatch = Process.argv.includes("--lua-watch")
const dirSource = Process.cwd()
// TODO make this a command line arg for re-use with other addons
const target = "Quiver.bundle.lua"

const predOutputFile = (filename) =>
	filename.endsWith(".bundle.lua")

if (!predOutputFile(target)) {
	console.error([
		"-- Invalid bundle name:",
		target,
		"-- Must end with:",
		".bundle.lua",
	].join("\n"))
	Process.exit(1)
}

// Colored text in terminal:
// https://stackoverflow.com/a/41407246
const colorize = text => "\x1b[33m" + text + "\x1b[0m"

const runBundler = async (trigger) => {
	const tStart = performance.now()
	// https://github.com/Benjamin-Dobell/luabundle
	const bundledLua = bundle("Main.lua", {
		isolate: true,
		luaVersion: 5.1,
		metadata: false,// un-bundling requires true
		// (name: string, packagePaths: readonly string[]) => string | null
		resolveModule: (name, _packagePaths) => "./" + name,
	})
	await Fs.writeFile(target, bundledLua, { flag: "w" })
	const time = (performance.now() - tStart).toFixed(0).padStart(3, " ")
	console.log(`${colorize(time)}ms -- ${target} [${trigger}]`)
}

await runBundler("Startup")

if (isWatch) {
	const throttle = ThrottleF(10)
	// https://bun.sh/guides/read-file/watch
	const watcher = Fs.watch(dirSource, { recursive: true })
	for await (const { eventType, filename } of watcher) {
		if (!filename) {
			// Can this happen?
		}
		else if (predOutputFile(filename)) {
			// Don't watch output
		}
		else if (filename.match(/.+\.lua$/)) {
			await throttle(() => runBundler(eventType))
		}
	}
}
