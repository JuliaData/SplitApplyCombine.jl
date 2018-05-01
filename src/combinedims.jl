"""
    combinedims(array_of_arrays)

Combines the dimensions of a nested array structure into a new, flat array.

This is the inverse operation of `splitdims` / `splitdimsview`.

See also `combinedimsview`, the lazy version of this function.
"""
combinedims(a::AbstractArray{<:AbstractArray{<:Any, N}, M}) where {N,M} = _combinedims(a, Val(ntuple(identity, Val(N))))

function _combinedims(a::AbstractArray, ::Val{dims}) where {dims}
    outeraxes = axes(a)
    inneraxes = _inneraxes(a)
    newaxes = (outeraxes..., inneraxes...,) # TODO support permutation
    T = inner_eltype(a)

    out = similar(a, T, newaxes)
    for i in CartesianIndices(outeraxes)
        for j in CartesianIndices(inneraxes)
            out[i.I..., j.I...] = a[i][j]
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

Base.axes(a::CombineDimsArray) = (axes(parent(a))..., axes(first(parent(a)))...)
Base.IndexStyle(::CombineDimsArray) = Base.IndexCartesian()
@propagate_inbounds function Base.getindex(a::CombineDimsArray{T, N}, i::Vararg{Int, N}) where {T, N}
    outer_ndims = ndims(parent(a))
    inner_ndims = _subtract(N, outer_ndims)
    outer_inds = ntuple(j -> @inbounds(i[j]), Val(outer_ndims))
    inner_inds = ntuple(j -> @inbounds(i[j+outer_ndims]), Val(inner_ndims))
    return parent(a)[outer_inds...][inner_inds...]
end

function combinedimsview(a::AbstractArray{<:AbstractArray{T, N}, M}) where {T, N, M}
    return CombineDimsArray{inner_eltype(a), _add(N, M), typeof(a)}(a)
end

@pure _add(a::Int, b::Int) = a + b