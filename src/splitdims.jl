"""
    splitdims(array, [dims])

Eagerly split the contents of `array` into a nested array of arrays. The outermost
array contains the specified dimension(s) `dims`, which may be an integer, a
tuple of integers, or defaults to the final array dimension. The nested arrays
will contain all the remaining dimensions (in ascending order).

See also `splitdimsview`, which performs a similar operation lazily.

#### Examples:

```julia
julia> splitdims([1 2; 3 4])
2-element Array{Array{Int64,1},1}:
 [1, 3]
 [2, 4]

julia> splitdims([1 2; 3 4], 1)
2-element Array{Array{Int64,1},1}:
 [1, 2]
 [3, 4]
```
"""
@inline splitdims(a::AbstractArray, i::Int) = _splitdims(a, Val((i,))) # @inline forces constant propagation
@inline splitdims(a::AbstractArray) = _splitdims(a, Val((ndims(a),)))
@inline splitdims(a::AbstractArray{<:Any, 0}) = _splitdims(a, Val(()))
@inline splitdims(a::AbstractArray, dims::Tuple{Vararg{Int}}) = _splitdims(a, Val(dims))

function _splitdims(a::AbstractArray{<:Any, n}, ::Val{dims}) where {n, dims}
    innerdims = default_innerdims(dims, n)
    check_dims(Val(n), Val(dims), Val(innerdims))

    allaxes = axes(a)
    outeraxes = getindices(allaxes, dims)
    inneraxes = getindices(allaxes, innerdims)

    local out
    alloc = false
    for i in CartesianIndices(outeraxes)
        inds = slice_inds(i, Val(dims), Val(n))
        tmp = getindices(a, inds...)
        if !alloc
            out = similar(a, typeof(tmp), outeraxes)
            alloc = true
        end
        out[i] = tmp
    end
    return out
end

@pure function default_innerdims(dims::Tuple{Vararg{Int}}, n::Int)
    t = ()
    for i in 1:n
        if !(i in dims)
            t = (i, t...)
        end
    end
    return t
end

@generated function check_dims(::Val{n}, ::Val{dims}, ::Val{innerdims}) where {n, dims, innerdims}
    d = (dims..., innerdims...)
    if length(d) != n
        error("Incorrect dimensions")
    end
    for i in 1:n
        if !(i in d)
            error("Incorrect dimensions")
        end
    end
    return nothing
end

@static if VERSION < v"0.7-"
    @generated function slice_inds(i::CartesianIndex, ::Val{dims}, ::Val{n}) where {dims, n}
        out = []
        for j in 1:n
            k = findfirst(dims .== j)
            if k === 0
                out = [out..., :]
            else
                out = [out..., :(i[$k])]
            end
        end
        return :(tuple($(out...)))
    end
else
    @generated function slice_inds(i::CartesianIndex, ::Val{dims}, ::Val{n}) where {dims, n}
        out = []
        for j in 1:n
            k = findfirst(==(j), dims)
            if k === nothing
                out = [out..., :]
            else
                out = [out..., :(i[$k])]
            end
        end
        return :(tuple($(out...)))
    end
end

## Lazy version

struct SplitDimsArray{T, N, Dims, A} <: AbstractArray{T, N}
    parent::A
end

Base.parent(a::SplitDimsArray) = a.parent

axes(a::SplitDimsArray{T, N, Dims}) where {T, N, Dims} = getindices(axes(parent(a)), Dims)
Base.IndexStyle(::SplitDimsArray) = Base.IndexCartesian()
@propagate_inbounds function Base.getindex(a::SplitDimsArray{T, N, Dims}, i::Int...) where {T, N, Dims}
    return view(parent(a), slice_inds(CartesianIndex(i), Val(Dims), Val(ndims(parent(a))))...)
end

"""
    splitdimsview(array, [dims])

Lazily split the contents of `array` into a nested array of arrays. The outermost
array contains the specified dimension(s) `dims`, which may be an integer, a
tuple of integers, or defaults to the final array dimension. The nested arrays
will contain all the remaining dimensions (in ascending order).

See also `splitdims`, which performs a similar operation eagerly.

#### Examples:

```julia
julia> splitdims([1 2; 3 4])
2-element SplitDimsArray{SubArray{Int64,1,Array{Int64,2},Tuple{Base.Slice{Base.OneTo{Int64}},Int64},true},1,(2,),Array{Int64,2}}:
 [1, 3]
 [2, 4]

julia> splitdims([1 2; 3 4], 1)
2-element SplitDimsArray{SubArray{Int64,1,Array{Int64,2},Tuple{Int64,Base.Slice{Base.OneTo{Int64}}},true},1,(1,),Array{Int64,2}}:
 [1, 2]
 [3, 4]
```
"""
@inline splitdimsview(a::AbstractArray) = SplitDimsArray{new_eltype(typeof(a), Val((ndims(a),))), 1, (ndims(a),), typeof(a)}(a)
@inline splitdimsview(a::AbstractArray{<:Any, 0}) = SplitDimsArray{new_eltype(typeof(a), Val(())), 0, (), typeof(a)}(a)
@inline splitdimsview(a::AbstractArray, i::Int) = SplitDimsArray{new_eltype(typeof(a), Val((i,))), 1, (i,), typeof(a)}(a)
@inline function splitdimsview(a::AbstractArray{<:Any, N}, dims::NTuple{M, Int}) where {N, M}
    SplitDimsArray{new_eltype(typeof(a), Val(dims)), M, dims, typeof(a)}(a)
end

@pure _subtract(N::Int, M::Int) = N - M

@static if VERSION < v"0.7-"
    function new_eltype(::Type{A}, ::Val{Dims}) where {A, Dims}
        return Core.Inference.return_type(view, splat_inds(Tuple{A, Core.Inference.return_type(slice_inds, Tuple{CartesianIndex{length(Dims)}, Val{Dims}, Val{ndims(A)}})}))
    end
else
    function new_eltype(::Type{A}, ::Val{Dims}) where {A, Dims}
        return Core.Compiler.return_type(view, splat_inds(Tuple{A, Core.Compiler.return_type(slice_inds, Tuple{CartesianIndex{length(Dims)}, Val{Dims}, Val{ndims(A)}})}))
    end
end

@pure function splat_inds(::Type{T}) where {T <: Tuple}
    a = T.parameters[1]
    b = T.parameters[2].parameters
    return Tuple{a, b...}
end
