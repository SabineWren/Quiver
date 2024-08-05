/**
 * Executes a callback one time after specified duration. All calls return
 * a continuation that resolve with a reference to the callback's output.
 * @param {number} ms time to throttle
 * @returns {Promise<unknown>}
 */
export const ThrottleF = (ms) => {
	let timeout = 0
	let isFirst = true

	// Maintain collection of all requests for continuation passing
	let resolvers = new Set()
	const resolveAll = x => {
		resolvers.forEach(r => r(x))
		resolvers = new Set()
		isFirst = true
	}
	const sharePromise = () => {
		const { p, resolve } = makeFuture()
		resolvers.add(resolve)
		return p
	}

	return (callback) => {
		// Cancel the previous request
		if (isFirst) isFirst = false
		else clearTimeout(timeout)

		// Throttle callback; this will be cancelled if another request comes in
		timeout = setTimeout(() => callback().then(resolveAll), ms)

		return sharePromise()
	}
}

// Allows resolving a promise from the outside
const makeFuture = () => {
	let res
	const p = new Promise((r, _) => { res = r })
	return { p, resolve: x => res(x) }
}
