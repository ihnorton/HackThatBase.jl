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

function gdc(expr)
    head = expr.head
    args = expr.args
    
    head in [:call, :typealias, :ref] &&
                         return args[1]
    head == :type     && return args[2]
    head == :const    && return gdc(args[1])
    head == :function && return args[1].args[1]
    
    head == :(=) && if isa(args[1], Symbol)
        return args[1]
    else
        return gdc(args[1])
    end
    nothing
end

function body_decls(body)
    res = []
    
    for ex in body
        s = gdc(ex)
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

    exclusions = get!(HackThatBase.exclusions, wspath, HackThatBase.get_names(wspath))

    function batchimp(M, exc)
        for n in filter(x->!(x in exc), names(eval(M), true, true))
            eval(Expr(:import, M, n))
        end
    end

    batchimp(:Base, [:__init__, :eval, exclusions...])

    importexprs =  map(x->Expr(:import, :Base, x), setdiff(names(Base,true,true), exclusions))

    rexp = Expr(:toplevel, Expr(:module, false, esc(wname),
        quote
        eval(M,x) = Core.eval(M,x)
        eval(x) = Core.eval($(esc(wname)), x)

        #importall Core.Intrinsics
        #importall Base.Operators

        import Base: vcat, include, call, Base, names, filter,
               !, !=, in, getindex, length, ceil, Bottom, Any, assert, zeros

        $importexprs
        include($wspath)

        end)) # quote
    # macro needs to be toplevel, and strip the surrounding block
    #Expr(:toplevel, rexp.args[2])
end

end # module HackThatBase
