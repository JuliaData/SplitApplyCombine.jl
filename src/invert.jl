"""
    invert(a)

Return a new nested container by reversing the order of the nested container `a`, for
example turning a dictionary of arrays into an array of dictionaries, such that 
`a[i][j] === invert(a)[j][i]`.

Note that in order for the keys of the inner and outer structure to be known, the input
container `a` must not be empty. 

# Examples

```julia
julia> invert([[1,2,3],[4,5,6]])
3-element Array{Array{Int64,1},1}:
 [1, 4]
 [2, 5]
 [3, 6]

julia> invert((a = [1, 2, 3], b = [2.0, 4.0, 6.0]))
3-element Array{NamedTuple{(:a, :b),Tuple{Int64,Float64}},1}:
 (a = 1, b = 2.0)
 (a = 2, b = 4.0)
 (a = 3, b = 6.0)
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
        exprs = [:(tuple($([:(a[$j][$i]) for j in 1:n]...))) for i in 1:m]
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

    if @generated
        return quote
            @inbounds for i in keys(out)
                out[i] = $(:(tuple($([:( a[$j][i] ) for j in 1:n]...))))
            end

            return out
        end
    else
        @inbounds for i in keys(out)
            out[i] = map(x -> @inbounds(x[i]), a)
        end

        return out
    end
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
@inline function invert(a::NamedTuple{names1, <:Tuple{Vararg{NamedTuple{names2}}}}) where {names1, names2}
    if @generated
        exprs = [:(NamedTuple{names1}(tuple($([:(getfield(getfield(a, $(QuoteNode(n1))), $(QuoteNode(n2)))) for n1 in names1]...)))) for n2 in names2]
        return :(NamedTuple{names2}(tuple($(exprs...))))
    else
        NamedTuple{names2}(ntuple(i -> NamedTuple{names1}(ntuple(j -> getfield(getfield(a, names1[j]), names2[i]), Val(length(names1)))), Val(length(names2))))
    end
end


# NamedTuple-Array
@inline function invert(a::NamedTuple{names, <:Tuple{Vararg{AbstractArray}}}) where {names}
    arrayinds = keys(a[1])

    @boundscheck for x in a
        if keys(x) != arrayinds
            error("indices are not uniform")
        end
    end
    
    T = _eltypes(typeof(a))
    out = similar(first(a), NamedTuple{names, T})

    @inbounds invert!(out, a)
end

@inline function invert!(out::AbstractArray{<:NamedTuple{names}}, a::NamedTuple{names, <:Tuple{Vararg{AbstractArray}}}) where names
    @boundscheck for x in a
        if keys(x) != keys(out)
            error("indices do not match")
        end
    end

    if @generated
        return quote
            @inbounds for i in keys(out)
                out[i] = $(:(NamedTuple{names}(tuple($([:( a[$(QuoteNode(n))][i] ) for n in names]...)))))
            end

            return out
        end
    else
        @inbounds for i in keys(out)
            out[i] = map(x -> @inbounds(x[i]), a)
        end

        return out
    end
end

# TODO check that the AbstractArrays have all their type parameters
@pure function _eltypes(::Type{NamedTuple{names, T}}) where {names, T <: Tuple{Vararg{AbstractArray}}}
    types = T.parameters
    eltypes = map(eltype, types)
    return Tuple{eltypes...}
end


# Array-NamedTuple
struct GetFielder{name}
end

GetFielder(name::Symbol) = GetFielder{name}()
(::GetFielder{name})(x) where {name} = getfield(x, name)

@inline function invert(a::AbstractArray{<:NamedTuple{names}}) where {names}
    if @generated
        exprs = [ :(map($(GetFielder(n)), a)) for n in names ]
        return :( NamedTuple{names}(tuple($(exprs...))) )
    else    
        NamedTuple{names}(ntuple(i -> map(x -> getfield(x, names[i]), a), Val(n)))
    end
end

# NamedTuple-Tuple
@inline function invert(a::NamedTuple{names1, <:Tuple{Vararg{Any, n}}}) where {names1, n}
    if @generated
        exprs = [:(NamedTuple{names1}(tuple($([:(getfield(getfield(a, $(QuoteNode(n1))), $i)) for n1 in names1]...)))) for i in 1:n]
        return :(tuple($(exprs...)))
    else
        ntuple(i -> NamedTuple{names1}(ntuple(j -> getfield(getfield(a, names1[j]), i), Val(length(names1)))), Val(n))
    end
end

# Tuple-NamedTuple
@inline function invert(a::Tuple{Vararg{NamedTuple{names2}, n}}) where {n, names2}
    if @generated
        exprs = [:(tuple($([:(getfield(getfield(a, $i), $(QuoteNode(n2)))) for i in 1:n]...))) for n2 in names2]
        return :(NamedTuple{names2}(tuple($(exprs...))))
    else
        NamedTuple{names2}(ntuple(i -> ntuple(j -> getfield(getfield(a, j), names2[i]), Val(n)), Val(length(names2))))
    end
end

# Dict-Dict

# Dict-Array

# Array-Dict

# Dict-Tuple

# Tuple-Dict

# NamedTuple-Dict

# Dict-NamedTuple
