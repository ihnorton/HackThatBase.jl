module HackThatBase
export @hack, lminfo, showast

const isdist = isdir(joinpath(JULIA_HOME, "../share"))
const basepath = isdist ? joinpath(JULIA_HOME, "../share/julia/base") :
                          joinpath(JULIA_HOME, "../../base")

exclusions = Dict()

# return all expressions in given stream
function get_exprs(str)
    res = Expr[]
    lpos = 1
    while lpos < length(str)
        ex,lpos = parse(str, lpos; greedy=true, raise=false)
        isa(ex,Expr) && push!(res, ex)
    end
    return res
end
# return all expressions in given file
file_exprs(fname) = get_exprs(readall(open(fname,"r")))

# returns the declaration name for a given expression
# TODO: make sure all top-level expression heads are handled
function decl_name(expr)
    head = expr.head
    args = expr.args

    head in [:call, :typealias, :ref] &&
                         return args[1]
    head == :type     && return args[2]
    head == :const    && return decl_name(args[1])
    head == :function && return args[1].args[1]

    head == :(=) && if isa(args[1], Symbol)
        return args[1]
    else
        return decl_name(args[1])
    end
    #warn("Unhandled decl: ", head)
    nothing
end

# get all top-level declaration symbols
function body_decls(body)
    res = Any[]
    for ex in body
        s = decl_name(ex)
        s != nothing && push!(res,s)
    end
    res
end
get_names(fname) = body_decls(file_exprs(fname))

macro hack(wname, wpath)
    wsname = string(wname); wspath = string(wpath)

    wspath = joinpath(basepath, string(wspath,endswith(wspath,".jl") ? "":".jl"))

    # don't import these names. importing __init__ appears to deadlock the REPL
    exclusions = [:__init__, :eval, :func_for_method]

    body_exprs = HackThatBase.file_exprs(wspath)
    body_decls = HackThatBase.body_decls(body_exprs)

    # build and cache full list of exclusions:
    # don't import any top-level declarations found in the given file,
    # because those imports will conflict with Base versions
    exclusions = get!(HackThatBase.exclusions, wspath,
                      [exclusions; body_decls])

    # set up imports
    importnames = setdiff(names(Base,true,true), exclusions)
    importexprs =  map(x->Expr(:import, :Base, x), setdiff(names(Base,true,true), exclusions))

    # build module Expr. Quoting is a pain for module and import statements,
    # so build most of it directly.
    rexp = Expr(:toplevel, Expr(:module, false, esc(wname),
                Expr(:block,
                    Expr(:toplevel, Expr(:import, :Base, :getindex)),
                    Expr(:toplevel, importexprs...),

                    esc(quote
                            eval(M,x) = Core.eval(M,x)
                            eval(x) = Core.eval($wname, x)
                        end),
                    Expr(:toplevel, [esc(x) for x in body_exprs]...)
                )))
end

# helper function, returns args for typeinf
function lminfo(f::Function, args)
    m = Base._methods(f, args, -1)[1]
    linfo = Base.func_for_method(m[3], args, m[2])
    return (linfo, m[1], m[2])
end

showast(linfo, ast) = ccall(:jl_uncompress_ast, Any, (Any,Any), linfo, ast)

end # module HackThatBase
