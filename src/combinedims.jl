"""
    combinedims(array_of_arrays)

Combine the dimensions of a nested array structure into a new, flat array.

This is the inverse operation of `splitdims` / `splitdimsview`.

See also `combinedimsview`, the lazy version of this function.

# Example

```julia
julia> combinedims([[1, 2], [3, 4]])
2×2 Array{Int64,2}:
 1  3
 2  4
```
"""
combinedims(a::AbstractArray{<:AbstractArray{<:Any, N}, M}) where {N,M} = _combinedims(a, Val(ntuple(identity, Val(N))))

function _combinedims(a::AbstractArray, ::Val{dims}) where {dims}
    outeraxes = axes(a)
    inneraxes = _inneraxes(a)
    newaxes = (inneraxes..., outeraxes...) # TODO support permutation
    T = inner_eltype(a)

    out = similar(a, T, newaxes)
    for i in CartesianIndices(inneraxes)
        for j in CartesianIndices(outeraxes)
            out[i.I..., j.I...] = a[j][i]
        end
    end
    return out
end

_inneraxes(a) = axes(first(a)) # Can specialize this for static arrays, for example

inner_eltype(a) = Any
inner_eltype(a::AbstractArray{<:AbstractArray{T}}) where {T} = T


## Lazy version

struct CombineDimsArray{T, N, A} <: AbstractArray{T, N}
    parent::A
end

Base.parent(a::CombineDimsArray) = a.parent

Base.size(a::CombineDimsArray) = (size(first(parent(a)))..., size(parent(a))...)
axes(a::CombineDimsArray) = (axes(first(parent(a)))..., axes(parent(a))...)
Base.IndexStyle(::CombineDimsArray) = Base.IndexCartesian()
@propagate_inbounds function Base.getindex(a::CombineDimsArray{T, N}, i::Vararg{Int, N}) where {T, N}
    outer_ndims = ndims(parent(a))
    inner_ndims = N - outer_ndims
    outer_inds = ntuple(j -> @inbounds(return i[j+inner_ndims]), Val(outer_ndims))
    inner_inds = ntuple(j -> @inbounds(return i[j]), Val(inner_ndims))
    return parent(a)[outer_inds...][inner_inds...]
end

"""
    combinedimsview(array_of_arrays)

Lazily create a flat array view of a nested array structure.

This is the inverse operation of `splitdims` / `splitdimsview`.

See also `combinedims`, the eager version of this function.
"""
function combinedimsview(a::AbstractArray{<:AbstractArray{T, N}, M}) where {T, N, M}
    return CombineDimsArray{inner_eltype(a), N + M, typeof(a)}(a)
end