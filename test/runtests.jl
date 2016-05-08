using HackThatBase
using Base.Test

func(x,y) = x + y
args = lminfo(func, (Int, Float64))

#cd(joinpath(JULIA_HOME, "..", "..", "base"))
cd(splitdir(Base.find_source_file("inference.jl"))[1])
@hack W inference
result = W.typeinf_uncached(args...)
@test isa(result[1], LambdaInfo)
@test result[2] == Float64
@test result[3] == true
