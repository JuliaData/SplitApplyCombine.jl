module SplitApplyCombine

using Base: @propagate_inbounds, @pure, promote_op, ht_keyindex2!, Generator, @default_eltype

import JuliennedArrays: Reduce
export Reduce

import LightQuery: Names
export Names

import Base: merge, merge!, size, IndexStyle, getindex, parent, axes, keys, empty, getindex, collect
import Base.Iterators: Filter, ProductIterator, product, flatten
# collections -> scalar
export single

# collections -> collections
export Generator, flatten, product

# collections -> collections of collections
export group

# collections of collections -> collections of collections
export invert, invert! # a "transpose" for nested containers
export leftgroupjoin

include("single.jl")
include("map.jl")
include("group.jl")
include("innerjoin.jl")
include("leftgroupjoin.jl")
include("invert.jl")

# Silly definitions missing from Base
# ===================================
# this should always work
Base.haskey(a, i) = i ∈ keys(a)

end # module
