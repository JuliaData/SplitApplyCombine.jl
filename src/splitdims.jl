"""
    splitdims(array, [dims])

Split the contents of `array` into a nested array of arrays. The outermost
array contains the specified dimension(s) `dims`, which may be an integer, a
tuple of integers, or defaults to the final array dimension. The nested arrays
will contain all the remaining dimensions (in ascending order).

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
splitdims(a::AbstractArray, i::Int) = _splitdims(a, Val((i,)))
splitdims(a::AbstractArray) = _splitdims(a, Val((ndims(a),)))
splitdims(a::AbstractArray{0}) = _splitdims(a, Val(()))
splitdims(a::AbstractArray, dims::Tuple{Vararg{Int}}) = _splitdims(a, Val(dims))

@inline function _splitdims(a::AbstractArray{<:Any, n}, ::Val{dims}) where {n, dims}
    innerdims = default_innerdims(dims, n)
    check_dims(Val(n), Val(dims), Val(innerdims))

    allaxes = axes(a)
    outeraxes = getindices(allaxes, dims)
    inneraxes = getindices(allaxes, innerdims)

    local out
    alloc = false
    for i in CartesianIndices(outeraxes)
        inds = slice_inds(i, Val(dims), Val(n))
        tmp = a[inds...]
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

@generated function slice_inds(i::CartesianIndex, ::Val{dims}, ::Val{n}) where {dims, n}
    out = []
    for j in 1:n
        k = findfirst(equalto(j), dims)
        if k == 0
            out = [out..., :]
        else
            out = [out..., :(i[$k])]
        end
    end
    return :(tuple($(out...)))
end
