module SplitApplyCombine

using Base: @propagate_inbounds, @pure, promote_op
using Indexing

# collections -> scalar
export single

# collections -> collections
import Base: merge, merge!, size, IndexStyle, getindex, parent, axes, ht_keyindex2!, iterate
export mapmany, mapview, MappedIterator, MappedArray

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

# Silly definitions missing from Base
# ===================================
# this should always work
Base.haskey(a, i) = i ∈ keys(a) 

end # module
