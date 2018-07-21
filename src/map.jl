"""
    mapmany(f, a...)

Like `map`, but `f(x)` for each `x ∈ a` may return an arbitrary number of values to insert
into the output.

# Example

```jldoctest
julia> mapmany(x -> 1:x, [1,2,3])
6-element Array{Int64,1}:
 1
 1
 2
 1
 2
 3
```
"""
function mapmany(f, a)
    T = eltype(promote_op(f, eltype(a)))
    out = T[]
    for x ∈ a
        append!(out, f(x))
    end
    return out
end

mapmany(f, a, b, c...) = mapmany(x->f(x...), zip(a, b, c...))

"""
    flatten(a)

Takes a collection of collections `a` and returns a collection containing all the elements
of the subcollecitons of `a`. Equivalent to `mapmany(idenity, a)`.

# Example

```jldoctest
julia> flatten([1:1, 1:2, 1:3])
6-element Array{Int64,1}:
 1
 1
 2
 1
 2
 3
```
"""
flatten(x) = mapmany(identity, x) 

struct MappedIterator{F, T}
	f::F
	parent::T
end
@inline function iterate(it::MappedIterator)
	x = iterate(it.parent)
	return x === nothing ? nothing : (it.f(x[1]), x[2])
end
@inline function iterate(it::MappedIterator, i)
	x = iterate(it.parent, i)
	return x === nothing ? nothing : (it.f(x[1]), x[2])
end
# TODO HasLength, HasShape, etc...

struct MappedArray{T, N, F, A <: AbstractArray{<:Any, N}} <: AbstractArray{T, N}
	f::F
	parent::A
end
parent(a::MappedArray) = a.parent
size(a::MappedArray) = size(a.parent)
axes(a::MappedArray) = axes(a.parent)
IndexStyle(a::MappedArray) = IndexStyle(a.parent)
@propagate_inbounds getindex(a::MappedArray{T}, i::Int) where {T} = a.f(a.parent[i])::T
@propagate_inbounds getindex(a::MappedArray{T}, i::Int...) where {T} = a.f(a.parent[i...])::T

"""
    mapview(f, a)

Return a container equivalent to `map(f, a)`.
"""
mapview(f, a) = MappedIterator(f, a)
mapview(f, a::AbstractArray{T, N}) where {T, N} = MappedArray{promote_op(f, T), N, typeof(f), typeof(a)}(f, a)
mapview(f, a::Tuple) = map(f, a)
mapview(f, a::NamedTuple) = map(f, a)

mapview(::typeof(identity), a) = a
mapview(::typeof(identity), a::AbstractArray) = a
mapview(::typeof(identity), a::Tuple) = a
mapview(::typeof(identity), a::NamedTuple) = a