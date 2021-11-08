module SplitApplyCombine

using Base: @propagate_inbounds, @pure, promote_op, Callable
using Indexing
using Dictionaries
import Dictionaries: filterview

import Base: merge, merge!, size, IndexStyle, getindex, parent, axes, iterate

# collections -> scalar
if VERSION < v"1.4.0-DEV"
    export only
    include("only.jl")
end

# collections -> collections
export mapmany, mapview, MappedIterator, MappedArray, product, productview, ProductArray, filterview

# collections -> collections of collections
export group, groupfind, GroupDictionary, groupview, groupreduce, groupcount, groupsum, groupprod, groupunique, grouponly, groupfirst, grouplast
export splitdims, splitdimsview, SplitDimsArray

# colletions of collections -> collections
export flatten #, flattenview
export combinedims, combinedimsview, CombineDimsArray

# collections of collections -> collections of collections
export invert, invert! # a "transpose" for nested containers
export innerjoin, ⨝, leftgroupjoin

@inline former(a, b) = a
@inline latter(a, b) = b

include("map.jl")
include("group.jl")
include("product.jl")
include("innerjoin.jl")
include("leftgroupjoin.jl")
include("splitdims.jl")
include("combinedims.jl")
include("invert.jl")

# Silly definitions missing from Base
# ===================================
# this should always work
Base.haskey(a, i) = i ∈ keys(a) 

if VERSION < v"1.2"
    keytype(a::AbstractArray) = eltype(keys(a))
    keytype(a) = Base.keytype(a)
end

end # module
