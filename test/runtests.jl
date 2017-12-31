using SplitApplyCombine
if VERSION < v"0.7-"
    using Base.Test
else
    using Test
end

include("group.jl")
include("innerjoin.jl")
include("leftgroupjoin.jl")
include("only.jl")
include("map.jl")
include("splitdims.jl")

include("underscore.jl")
