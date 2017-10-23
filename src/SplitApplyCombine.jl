module SplitApplyCombine

using Base: @propagate_inbounds, promote_op

# Syntax
export @_

# collections -> scalar
export only

# collections -> collections
import Base: merge, merge!
export mapmany

# collections -> collections of collections
export group, groupinds, Groups, groupview, groupreduce

# colletions of collections -> collections
export flatten #, flattenview

# collections of collections -> collections of collections
export innerjoin, ⨝, leftgroupjoin
# `pivot` or similar - like transpose, but nested.

include("only.jl")
include("merge.jl")
include("map.jl")
include("group.jl")
include("innerjoin.jl")
include("leftgroupjoin.jl")

# Syntax
include("underscore.jl")


# Silly definitions missing from Base
# ===================================
# this should always work
Base.haskey(a, i) = i ∈ keys(a) 

# A Nullable is a container with 0 or 1 values... so...
Base.start(::Nullable) = false
Base.done(n::Nullable, i::Bool) = isnull(n) | i
Base.next(n::Nullable, i::Bool) = (n.valie, true)
Base.first(n::Nullable) = get(n)
Base.last(n::Nullable) = get(n)
@propagate_inbounds function Base.getindex(n::Nullable)
    @boundscheck if !n.hasvalue
        return NullException()
    end
    return n.value
end

# mini-compat (more for my knowledge than anything)
if VERSION < v"0.7-"
    Base.keys(v::AbstractVector) = indices(v)[1]
    Base.keys(a::AbstractArray) = CartesianRange(indices(a)...)
    Base.keys(::NTuple{N,Any}) where {N} = Base.OneTo(N)
    Base.keys(::Number) = Base.OneTo(1)
end


end # module

# Random thoughts:

# merge! many other mutating ops returns collection, so:
# why does setindex! return the set value(s), not the collection???
