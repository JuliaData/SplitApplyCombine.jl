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
""" # Array-Array
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

    out = Array{Array{eltype(T),length(outersize)}}(undef, outersize)
    @inbounds for i in outerkeys
        out[i] = Array{eltype(T)}(undef, innersize)
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

# Tuple-tuple
@inline function invert(a::NTuple{n, NTuple{m, Any}}) where {n, m}
    if @generated
        exprs = [:(tuple($([:(a[$j][$i]) for j = 1:n]...))) for i = 1:m]
        return :(tuple($(exprs...)))
    else
        ntuple(i -> ntuple(j -> a[j][i], Val(n)), Val(m))
    end
end


# Tuple-Array
@inline function invert(a::NTuple{n, AbstractArray}) where {n}
    arrayinds = keys(a[1])

    @boundscheck for x in a
        if keys(x) != arrayinds
            error("indices are not uniform")
        end
    end
    
    T = _eltypes(typeof(a))
    out = similar(first(a), T)

    @inbounds invert!(out, a)
end

@inline function invert!(out::AbstractArray{<:NTuple{n, Any}}, a::NTuple{n, AbstractArray}) where n
    @boundscheck for x in a
        if keys(x) != keys(out)
            error("indices do not match")
        end
    end

    @inbounds for i in keys(out)
        out[i] = map(x -> @inbounds(x[i]), a)
    end

    return out
end

# Note that T is a concrete type, so the AbstractArrays should have all their type parameters
@pure function _eltypes(::Type{T}) where {T <: Tuple{Vararg{AbstractArray}}}
    types = T.parameters
    eltypes = map(eltype, types)
    return Tuple{eltypes...}
end

struct Indexer{i}
end

Indexer(i::Int) = Indexer{i}()
(::Indexer{i})(x) where {i} = @inbounds x[i]

# Array-Tuple
@inline function invert(a::AbstractArray{<:NTuple{n, Any}}) where {n}
    if @generated
        exprs = [ :(map($(Indexer(i)), a)) for i in 1:n ]
        return :( tuple($(exprs...)) )
    else    
        ntuple(i -> map(x -> x[i], a), Val(n))
    end
end

# NamedTuple-NamedTuple

# NamedTuple-Array

# Array-NamedTuple

# NamedTuple-Tuple

# Tuple-NamedTuple

# Dict-Dict

# Dict-Array

# Array-Dict

# Dict-Tuple

# Tuple-Dict

# NamedTuple-Dict

# Dict-NamedTuple
