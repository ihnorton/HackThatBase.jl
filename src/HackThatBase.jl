module HackThatBase
export @whisper
exclusions = Dict()

function get_exprs(str)
    res = Expr[]
    lpos = 1
    while lpos < length(str)
        ex,lpos = parse(str, lpos; greedy=true, raise=false)
        push!(res, ex)
    end
    return res
end

file_exprs(f) = get_exprs(readall(open(f,"r")))

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
    nothing
end

function body_decls(body)
    res = []
    
    for ex in body
        s = decl_name(ex)
        try
            s != nothing && push!(res,s)
        catch
            break    
        end
    end
    res
end
get_names(fname) = fname |> file_exprs |> body_decls

macro whisper(wname, wpath)
    wsname = string(wname); wspath = string(wpath)
    wspath = joinpath(JULIA_HOME, "../../base", string(wspath,endswith(wspath,".jl") ? "":".jl"))

    exclusions = get!(HackThatBase.exclusions, wspath,
                      [:__init__, :eval,HackThatBase.get_names(wspath)])
   
    importnames = setdiff(names(Base,true,true), exclusions)
    importexprs =  map(x->Expr(:import, :Base, x), setdiff(names(Base,true,true), exclusions))

    rexp = Expr(:toplevel, Expr(:module, false, esc(wname),
                Expr(:block,
                    Expr(:toplevel, Expr(:import, :Base, :getindex)),
                    Expr(:toplevel, importexprs...),
                    esc(:(
                        eval(M,x) = Core.eval(M,x),
                        eval(x) = Core.eval($wname, x),
                        include($wspath)
                    )))
                ))
end

end # module HackThatBase
