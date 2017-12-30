"""
    splitdims(array, [dims], [innerdims])

Split the contents of `array` into a nested array of arrays. The outermost
array contains the specified dimension(s) `dims`, which may be an integer, a
tuple of integers, or defaults to the final array dimension. The nested arrays
will contain all the remaining dimensions, in the order specified by `innerdims`
(defaulting to ascending order).
"""
splitdims(a::AbstractArray, i::Int) = splitdims(a, (i,))
splitdims(a::AbstractArray) = splitdims(a, (ndims(a),))
splitdims(a::AbstractArray{0}) = splitdims(a, ())

function splitdims(a::AbstractArray, dims::Tuple{Vararg{Int}})
    innerdims = default_innerdims(dims, ndims(a))
    return splitdims(a, dims, innerdims)
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

function splitdims(a::AbstractArray, dims::Tuple{Vararg{Int}}, innerdims::Tuple{Vararg{Int}})
    check_dims(ndims(a), dims, innerdims)

    allaxes = axes(a)
    outeraxes = getindices(allaxes, dims)
    inneraxes = getindices(allaxes, innerdims)

    local out
    alloc = false
    for i in CartesianIndices(outeraxes)
        inds = slice_inds(i, dims, ndims(a))
        tmp = a[inds...]
        if !alloc
            out = similar(a, typeof(tmp), outeraxes)
            alloc = true
        end
        out[i] = tmp
    end
    return out
end

@pure function check_dims(n::Int, dims::Tuple{Vararg{Int}}, innerdims::Tuple{Vararg{Int}})
    d = (dims..., innerdims...)
    if length(d) != n
        error("Incorrect dimensions")
    end
    for i in 1:n
        if !(i in d)
            error("Incorrect dimensions")
        end
    end
end

function slice_inds(i::CartesianIndex, dims, n)
    out = ()
    for j in 1:n
        k = findfirst(equalto(j), dims)
        if k == 0
            out = (out..., :)
        else
            out = (out..., i[k])
        end
    end
    return out
end
