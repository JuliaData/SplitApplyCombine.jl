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
function mapmany(f::Callable, a)
    T = eltype(promote_op(f, eltype(a)))
    afirst, state = iterate(a)
    arest = Iterators.rest(a, state)
    out = _similar_with_content(f(afirst), T)
    for x ∈ arest
        append!(out, f(x))
    end
    return out
end

_similar_with_content(A::AbstractVector, ::Type{T}) where {T} = similar(A, T) .= A
_similar_with_content(A::AbstractArray, ::Type{T}) where {T} = _similar_with_content(vec(A), T)
_similar_with_content(A, ::Type{T}) where {T} = append!(T[], A)

mapmany(f::Callable, a, b, c...) = mapmany(x->f(x...), zip(a, b, c...))

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

# Inherit any iteration and indexing properties from parent
Base.IteratorSize(it::MappedIterator) = Base.IteratorSize(it.parent)
Base.length(it::MappedIterator) = length(it.parent)
Base.size(it::MappedIterator) = size(it.parent)
Base.axes(it::MappedIterator) = axes(it.parent)
Base.keys(it::MappedIterator) = keys(it.parent)
@propagate_inbounds Base.getindex(it::MappedIterator, i) = it.parent[i]

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

Return a view of `a` where each element is mapped through function `f`. The iteration and
indexing properties of `a` are preserved. Similar to `map(f, a)`, except evaluated lazily.

# Example

```julia
julia> a = [1,2,3];

julia> b = mapview(-, a)
3-element MappedArray{Int64,1,typeof(-),Array{Int64,1}}:
 -1
 -2
 -3

julia> a[1] = 10;

julia> b
3-element MappedArray{Int64,1,typeof(-),Array{Int64,1}}:
 -10
  -2
  -3
```
"""
mapview(f, a) = MappedIterator(f, a)
mapview(f, a::AbstractArray{T, N}) where {T, N} = MappedArray{promote_op(f, T), N, typeof(f), typeof(a)}(f, a)
function mapview(f, d::AbstractDictionary)
    I = keytype(d)
    T = Core.Compiler.return_type(f, Tuple{eltype(d)})
    
    return MappedDictionary{I, T, typeof(f), Tuple{typeof(d)}}(f, (d,))
end

mapview(::typeof(identity), a) = a
mapview(::typeof(identity), a::AbstractArray) = a
mapview(::typeof(identity), d::AbstractDictionary) = d

"""
    filterview(f, a)

Return a view of an array `a` without elements for which `f` is `false`. Similar to `filter(f, a)`, except returns a view instead of a copy.
Filtered indices are computed once, and are not updated when the array gets modified.

# Example

```
julia> a = [1, 2, 3];

julia> b = filterview(isodd, a)
2-element view(::Vector{Int64}, [1, 3]) with eltype Int64:
 1
 3

julia> b[2] = 10;

julia> a
3-element Vector{Int64}:
  1
  2
 10

julia> b
2-element view(::Vector{Int64}, [1, 3]) with eltype Int64:
  1
 10
```
"""
filterview(f, a::AbstractArray) = @view a[findall(f, a)]
