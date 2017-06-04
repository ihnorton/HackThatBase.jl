using HackThatBase
using Base.Test

func(x,y) = x + y
args = lminfo(func, (Int, Float64))

cd(splitdir(Base.find_source_file("inference.jl"))[1])
@hack W inference
result = run_inference(W, args)
@test isa(result[2], CodeInfo)
@test result[3] == Float64
