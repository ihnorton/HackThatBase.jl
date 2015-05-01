Rebuilding the Julia system image is time-consuming, leading
to long round-trip times when modifying code in base. This
tool aims to reduce the turn-around time for testing changes
to `inference.jl`, the most compilation-heavy part of base.

This should work (but has not been tested) with other modular
parts of base, although it will almost certainly not work
with the REPL code.

##Usage##

```jl
using HackThatBase
func(x,y) = x + y
args = lminfo(func, (Int,Float64))   # (Int, Float64) are the types of x and y
@hack W inference
result = W.typeinf_uncached(args...)
```

After modifying `inference.jl`, simply re-run these steps to
execute the modified code:

```jl
@hack W inference
result = W.typeinf_uncached(args...)
```

To view the resulting inferred AST, use

```jl
showast(args[1], result[1])
```

Some explanation:
- `typeinf_uncached` is the (un-cached) entrypoint to type inference
- `lminfo` is a helper function to extract the method signature
   and other arguments to `typeinf`.

(on my system, the above steps take ~15 seconds to complete,
as compared to >2 minutes to rebuild the second stage of sysimg)

Notes:

- imports are limited in the test environment.
  To inspect variables, push to an array in `Main`.
  e.g. somewhere in `inference.jl`, do `push!(Main.foo, A)`
  (where `foo = []` at the REPL before running)

###Tips on usage with Debug.jl###

`HackThatBase` can be used in conjunction with the [Debug](https://github.com/toivoh/Debug.jl) package.
Because inference is used during the compilation of functions (including those called by inference), it's
advised that you first complete one run through `showast` before beginning debugging. For example,
let's say you've edited `inference.jl` and inserted some breakpoints. Here's how you should proceed:

```jl
shell> git stash       # temporarily go back to the unedited version of inference.jl
julia> using HackThatBase
julia> func(x,y) = x + y
julia> args = lminfo(func, (Int,Float64))   # (Int, Float64) are the types of x and y
julia> @hack W inference
julia> result = W.typeinf_uncached(args...)
julia> showast(args[1], result[1])
shell> git stash pop   # restore your edited version of inference.jl
julia> @hack W inference
julia> result = W.typeinf_uncached(args...)
```

At this point your breakpoints will be triggered.
