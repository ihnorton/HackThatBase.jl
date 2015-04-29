Rebuilding the Julia system image is time-consuming, leading
to long round-trip times when modifying code in base. This
tool aims to reduce the turn-around time for testing changes
to `inference.jl`, the most compilation-heavy part of base.

This should work (but has not been tested) with other modular
parts of base, although it will almost certainly not work
with the REPL code.

##Usage##

```
using HackThatBase
@hack W inference
args = lminfo(function, args)
W.typeinf_uncached(args...)
```

After modifying `inference.jl`, simply re-run these steps to
execute the modified code:

```
@hack W inference
W.typeinf_uncached(args...)
```

To view the resulting inferred AST, use HackThatBase.showast.

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
