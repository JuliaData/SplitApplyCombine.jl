using SplitApplyCombine
if VERSION < v"0.7-"
    using Base.Test
else
    using Test
end

include("single.jl")
include("splitdims.jl")
include("combinedims.jl")
include("map.jl")
include("group.jl")
include("innerjoin.jl")
include("leftgroupjoin.jl")

include("underscore.jl")
