/**
 * Executes a callback one time after specified duration. All calls return
 * a continuation that resolve with a reference to the callback's output.
 * @param {number} ms time to throttle
 * @returns {Promise<unknown>}
 */
export const ThrottleF = (ms: number) => {
	let timeout: NodeJS.Timeout
	let isFirst = true

	// Maintain collection of all requests for continuation passing
	let resolvers = new Set<(x: any) => void>()
	const resolveAll = <A>(x: A) => {
		resolvers.forEach(r => r(x))
		resolvers = new Set()
		isFirst = true
	}
	const sharePromise = <A>() => {
		const { p, resolve } = makeFuture<A>()
		resolvers.add(resolve)
		return p
	}

	return <A>(callback: () => Promise<A>) => {
		// Cancel the previous request
		if (isFirst) isFirst = false
		else clearTimeout(timeout)

		// Throttle callback; this will be cleared if another request comes in
		timeout = setTimeout(() => callback().then(resolveAll), ms)

		return sharePromise<A>()
	}
}

// Allows resolving a promise from the outside
const makeFuture = <A>() => {
	let res: (x: A) => void
	const p = new Promise((r, _) => { res = r }) as Promise<A>
	return { p, resolve: (x: A) => res(x) }
}
