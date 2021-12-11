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
combinedims(a::AbstractArray{<:AbstractArray{<:Any, N}, M}) where {N,M} = combinedims(a, ntuple(i -> N + i, M))
combinedims(a::AbstractArray{<:AbstractArray{<:Any, N}, 1}, outerdim::Int) where {N} = combinedims(a, (outerdim,))
combinedims(a::AbstractArray{<:AbstractArray{<:Any, N}, M}, outerdims::NTuple{M, Int}) where {N, M} = _combinedims(a, Val(outerdims))

function _combinedims(a::AbstractArray, ::Val{outer_dims}) where {outer_dims}
    outeraxes = axes(a)
    inneraxes = _inneraxes(a)
    ndims_total = length(outeraxes) + length(inneraxes)
    newaxes = _combine_tuples(ndims_total, outer_dims, outeraxes, inneraxes)

    T = inner_eltype(a)
    out = similar(a, T, newaxes)
    for j in CartesianIndices(outeraxes)
        I = slice_inds(j, Val(outer_dims), Val(ndims_total))
        out[I..., :] = a[j]  # trailing ':' is required for zero-dimensional a[j]
    end
    return out
end

@inline function _combine_tuples(n, dims, t_then, t_else)
    i_out = Ref(0)
    i_in = Ref(0)
    ntuple(n) do i
        i ∈ dims ? t_then[i_out[] += 1] : t_else[i_in[] += 1]
    end
end

_inneraxes(a) = axes(first(a)) # Can specialize this for static arrays, for example

inner_eltype(a) = Any
inner_eltype(a::AbstractArray{<:AbstractArray{T}}) where {T} = T


## Lazy version

struct CombineDimsArray{T, N, Nout, A} <: AbstractArray{T, N}
    parent::A
    outer_dims::NTuple{Nout, Int}
end

Base.parent(a::CombineDimsArray) = a.parent

@inline dims_outer(a::CombineDimsArray) = a.outer_dims
@inline function dims_inner(a::CombineDimsArray{T, N, Nout}) where {T, N, Nout}
    # below is a type-stable version of:
    # filter(∉(dims_outer(a)), ntuple(identity, N))
    i = Ref(0)
    ntuple(N - Nout) do _
        i[] = findnext(∉(dims_outer(a)), 1:N, i[] + 1)
    end
end

Base.size(a::CombineDimsArray) = _combine_tuples(ndims(a), dims_outer(a), size(parent(a)), size(first(parent(a))))
axes(a::CombineDimsArray) = _combine_tuples(ndims(a), dims_outer(a), axes(parent(a)), axes(first(parent(a))))
Base.IndexStyle(::CombineDimsArray) = Base.IndexCartesian()
@propagate_inbounds function Base.getindex(a::CombineDimsArray{T, N}, i::Vararg{Int, N}) where {T, N}
    outer_inds = getindices(i, dims_outer(a))
    inner_inds = getindices(i, dims_inner(a))
    return parent(a)[outer_inds...][inner_inds...]
end

"""
    combinedimsview(array_of_arrays)

Lazily create a flat array view of a nested array structure.

This is the inverse operation of `splitdims` / `splitdimsview`.

See also `combinedims`, the eager version of this function.
"""
combinedimsview(a::AbstractArray{<:AbstractArray{T, N}, M}) where {T, N, M} = combinedimsview(a, ntuple(i -> N + i, Val(M)))
combinedimsview(a::AbstractArray{<:AbstractArray{T, N}, 1}, outerdim::Int) where {T, N} = combinedimsview(a, (outerdim,))
combinedimsview(a::AbstractArray{<:AbstractArray{T, N}, M}, outerdims::NTuple{M, Int}) where {T, N, M} = CombineDimsArray{inner_eltype(a), N + M, M, typeof(a)}(a, outerdims)
