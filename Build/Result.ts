import { Exit } from "effect"
import { dual } from "effect/Function"

const Filter: {
  <A, E2>(predicate: (a: A) => boolean, onErr: (a: A) => E2): <E1>(self: Exit.Exit<A, E1>) => Exit.Exit<A, E1|E2>
  <A, E1, E2>(self: Exit.Exit<A, E1>, predicate: (a: A) => boolean, onErr: (a: A) => E2): Exit.Exit<A, E1|E2>
} = dual(3, <A, E1, E2>(
		self: Exit.Exit<A, E1>,
		predicate: (a: A) => boolean,
		onErr: (a: A) => E2,
	): Exit.Exit<A, E1 | E2> =>
		Exit.flatMap(self, x => predicate(x) ? Exit.succeed(x) : Exit.fail(onErr(x)))
)

export const Result = {
	...Exit,
	Ok: Exit.succeed,
	Error: Exit.fail,
	Filter,
}
