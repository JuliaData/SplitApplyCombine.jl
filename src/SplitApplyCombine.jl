module SplitApplyCombine

using Base: @propagate_inbounds, @pure, promote_op
using Indexing

# mini-compat (more for my knowledge than anything)
@static if VERSION < v"0.7-"
    const AbstractDict = Associative
    const axes = indices
    const ht_keyindex2! = Base.ht_keyindex2
    const CartesianIndices = CartesianRange

    Base.keys(v::AbstractVector) = indices(v)[1]
    Base.keys(a::AbstractArray) = CartesianRange(indices(a)...)
    Base.keys(::NTuple{N,Any}) where {N} = Base.OneTo(N)
    Base.keys(::Number) = Base.OneTo(1)

    @pure Base.Val(x) = Val{x}()
    @inline Base.ntuple(f, ::Val{x}) where {x} = ntuple(f, Val{x})
else
    import Base: axes, ht_keyindex2!
end

# Syntax
export @_

# collections -> scalar
export single

# collections -> collections
import Base: merge, merge!
export mapmany

# collections -> collections of collections
export group, groupinds, Groups, groupview, groupreduce
export splitdims, splitdimsview, SplitDimsArray

# colletions of collections -> collections
export flatten #, flattenview
export combinedims, combinedimsview, CombineDimsArray

# collections of collections -> collections of collections
export invert, invert! # a "transpose" for nested containers
export innerjoin, ⨝, leftgroupjoin

include("single.jl")
include("merge.jl")
include("map.jl")
include("group.jl")
include("innerjoin.jl")
include("leftgroupjoin.jl")
include("splitdims.jl")
include("combinedims.jl")
include("invert.jl")

# Syntax
include("underscore.jl")


# Silly definitions missing from Base
# ===================================
# this should always work
Base.haskey(a, i) = i ∈ keys(a) 


end # module
