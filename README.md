Rebuilding the Julia system image is time-consuming, leading
to long round-trip times when modifying code in base. This
tool aims to reduce the turn-around for testing such changes,
in particular to inference.jl (the most compilation-heavy part
of base).

##Usage##

```
using HackThatBase
@hack W inference
args = lminfo(function, args)
W.typeinf(args...)
```

After modifying `inference.jl`, simply re-run these steps to
execute the modified code:

```
@hack W inference
W.typeinf(args...)
```

(on my system, the above steps take ~15 seconds to complete,
as compared to >2 minutes to rebuild the second stage of sysimg)

Notes:

- to use this with inference, you *must* disable
  typinf caching. See `!is(tf,())` in `builtin_tfunction`.
  Otherwise the sysimg-cached version will be used, and
  no changes will be observed.

- imports are limited in the test environment.
  To inspect variables, push to an array in Main.
  e.g. `push!(Main.foo, A)`
  (where `foo = []` at the REPL before running)
