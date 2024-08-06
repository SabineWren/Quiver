export class Result {
	#r
	static Ok = (v) => {
		const r = new Result()
		r.#r = { _tag: "Ok", Val: v }
		return r
	}
	static Error = (c) => {
		const r = new Result()
		r.#r = { _tag: "Error", Cause: c }
		return r
	}
	static OfNullable = (v) =>
		v === undefined || v === null
			? Result.Error("Null or Undefined")
			: Result.Ok(v)

	// (>>=), flatMap, collect
	Bind = (f) =>
		this.#r._tag === "Error" ? this : f(this.#r.Val)
	Default = (val) =>
		this.#r._tag === "Error" ? val :this.#r.Val
	Filter = (c, pred) => {
		if (this.#r._tag === "Ok" && !pred(this.#r.Val))
			return Result.Error(c)
		else
			return this
	}
	GetSome = (onError) =>
		this.Match({ Ok: v => v, Error: onError })
	Map = (f) =>
		this.#r._tag === "Error"
			? this
			: Result.Ok(f(this.#r.Val))
	MapError = (f) =>
		this.#r._tag === "Error"
			? Result.Error(f(this.#r.Cause))
			: this
	Match = ({ Error, Ok }) => {
		if (this.#r._tag === "Error")
			return Error(this.#r.Cause)
		else
			return Ok(this.#r.Val)
	}
}
