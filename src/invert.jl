"""
    invert(a)

Return a new nested container by reversing the order of the nested container `a`, for
example turning a dictionary of arrays into an array of dictionaries, such that 
`a[i][j] === invert(a)[j][i]`.

Note that in order for the keys of the inner and outer structure to be known, the input
container `a` must not be empty. 

# Example

```julia
julia> invert([[1,2,3],[4,5,6]])
3-element Array{Array{Int64,1},1}:
 [1, 4]
 [2, 5]
 [3, 6]
```
"""
@inline function invert(a::AbstractArray{T}) where {T <: AbstractArray}
    f = first(a)
    innersize = size(a)
    outersize = size(f)
    innerkeys = keys(a)
    outerkeys = keys(f)

    @boundscheck for x in a
        if size(x) != outersize
            error("keys don't match")
        end
    end

    @static if VERSION < v"0.7-"
        out = Array{Array{eltype(T),length(outersize)}}(outersize)
        @inbounds for i in outerkeys
            out[i] = Array{eltype(T)}(innersize)
        end
    else
        out = Array{Array{eltype(T),length(outersize)}}(undef, outersize)
        @inbounds for i in outerkeys
            out[i] = Array{eltype(T)}(undef, innersize)
        end
    end

    return _invert!(out, a, innerkeys, outerkeys)
end

@propagate_inbounds function invert!(out::AbstractArray, a::AbstractArray)
    innerkeys = keys(a)
    outerkeys = keys(first(a))

    @boundscheck for x in a
        if keys(x) != outerkeys
            error("keys don't match")
        end
    end

    @boundscheck if keys(out) != outerkeys
        error("keys don't match")
    end

    @boundscheck for x in out
        if keys(x) != innerkeys
            error("keys don't match")
        end
    end

    return _invert!(out, a, innerkeys, outerkeys)
end

# Note: keys are assumed verified already
function _invert!(out, a, innerkeys, outerkeys)
    @inbounds for i ∈ innerkeys
        tmp = a[i]
        for j ∈ outerkeys
            out[j][i] = tmp[j]
        end
    end
    return out
end