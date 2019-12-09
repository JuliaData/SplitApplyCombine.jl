"""
    group(iter)
    group(by::Union{Function, Type}, iter)
    group(by::Union{Function, Type}, f::Union{Function, Type}, iter...)

Sorts the elements `x` of the iterable `iter` into groups labeled by `by(x)`,
transforming each element to `f(x)`, where `by` and `f` default to the `identity` function.
If multiple collections (of the same length) are provided, the transformations occur
elementwise.

# Example

```jldoctest
julia> group(iseven, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
HashDictionary{Bool,Array{Int64,1}} with 2 entries:
 false │ [1, 3, 5, 7, 9]
 true  │ [2, 4, 6, 8, 10]

julia> group(iseven, x -> x ÷ 2, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
HashDictionary{Bool,Array{Int64,1}} with 2 entries:
 false │ [0, 1, 2, 3, 4]
 true  │ [1, 2, 3, 4, 5]
```
"""
group(iter) = group(iter, iter)
group(by::Callable, iter) = group(mapview(by, iter), iter)
group(by::Callable, f::Callable, iter) = group(mapview(by, iter), mapview(f, iter))

# TODO multi-input mapview
#group(by::Callable, f::Callable, iter1, iter2) = group(mapview(by, iter1, iter2), mapview(f, iter1, iter2))
#group(by::Callable, f::Callable, iter1, iter2, iters...) = group(mapview(by, iter1, iter2, iters...), mapview(f, iter1, iter2, iters...))
group(by::Callable, f::Callable, iter1, iter2, iters...) = group((x -> by(x...)), (x -> f(x...)), zip(iter1, iter2, iters...))

"""
    group(groups, values)

Sorts the elements of `values` into groups labelled by the matching element from `groups`.

# Example

```julia
julia> group([true,false,true,false,true], [1,2,3,4,5])
2-element HashDictionary{Bool,Array{Int64,1}}
 false │ [2, 4]
  true │ [1, 3, 5]
```
"""
function group(groups, values)
    I = eltype(groups)
    T = eltype(values)

    out = HashDictionary{I, Vector{T}}()
    @inbounds for (group, value) in zip(groups, values)
        push!(get!(Vector{T}, out, group), value)
    end

    return out
end

function group(groups::AbstractArray, values::AbstractArray)
    I = eltype(groups) # TODO EltypeUnknown
    T = eltype(values) # TODO EltypeUnknown

    if keys(groups) != keys(values)
        throw(DimensionMismatch("dimensions must match"))
    end

    out = HashDictionary{I, Vector{T}}()
    @inbounds for i in keys(groups)
        group = groups[i]
        value = values[i]
        push!(get!(Vector{T}, out, group), value)
    end

    return out
end

function group(groups::AbstractDictionary, values::AbstractDictionary)
    I = eltype(groups)
    T = eltype(values)

    out = HashDictionary{I, Vector{T}}()

    if sharetokens(groups, values)
        @inbounds for token in tokens(groups)
            group = gettoken(groups, value)
            value = gettoken(values, groups)
            push!(get!(Vector{T}, out, group), value)
        end
    else
        if length(groups) != length(values)
            throw(KeyError("Indices must match"))
        end

        for (i, group) in pairs(groups)
            value = values[i]
            push!(get!(Vector{T}, out, group), value)
        end
    end

    return out
end


"""
    groupreduce(by, f, op, iter...; [init])

Applies a `mapreduce`-like operation on the groupings labeled by passing the elements of
`iter` through `by`. Mostly equivalent to `map(g -> reduce(op, g), group(by, f, iter))`,
but designed to be more efficient. If multiple collections (of the same length) are
provided, the transformations `by` and `f` occur elementwise.
"""
groupreduce(by::Callable, op::Callable, iter) = groupreduce(by, identity, op, iter)

groupreduce(by::Callable, f::Callable, op::Callable, iter1, iter2, iters...; kw...) = groupreduce((x -> by(x...)), (x -> f(x...)), op, zip(iter1, iter2, iters...); kw...)

function groupreduce(by::Callable, f::Callable, op::Callable, iter; kw...)
    groupreduce(op, mapview(by, iter), mapview(f, iter); kw...)
end

function groupreduce(op::Callable, groups, values; kw...)
    I = eltype(groups)
    nt = kw.data
    if nt isa NamedTuple{()}
        T = eltype(values)
    elseif nt isa NamedTuple{(:init,)}
        T = Core.Compiler.return_type(op, Tuple{typeof(nt.init), eltype(values)})
    else
        throw(ArgumentError("groupreduce doesn't support these keyword arguments: $(setdiff(keys(nt), (:init,)))"))
    end

    out = HashDictionary{I, T}()
    @inbounds for (group, value) in zip(groups, values)
        (hadtoken, token) = gettoken!(out, group)
        if hadtoken
            settokenvalue!(out, token, op(gettokenvalue(out, token), value))
        else
            if nt isa NamedTuple{()}
                settokenvalue!(out, token, value)
            else
                settokenvalue!(out, token, op(nt.init, value))
            end
        end
    end

    return out
end

"""
    groupsum(by, [f], iter)

Sum the elements of `iter` belonging to different groups, optionally mapping by `f`.
"""
groupsum(iter) = groupsum(identity, iter)
groupsum(by, iter) = groupsum(by, identity, iter)
groupsum(by, f, iter) = groupreduce(by, f, +, iter)

"""
    groupprod(by, [f], iter)

Multiply the elements of `iter` belonging to different groups, optionally mapping by `f`.
"""
groupprod(iter) = groupprod(identity, iter)
groupprod(by, iter) = groupprod(by, identity, iter)
groupprod(by, f, iter) = groupreduce(by, f, *, iter)

"""
    groupcount([by], iter)

Determine the number of elements of `iter` belonging to each group.
"""
groupcount(by, iter) = groupreduce(by, x->1, +, iter)
groupcount(iter) = groupcount(identity, iter) # A handy extension of `unique`


#=
groupunique(iter) = groupunique(identity, iter)

groupunique(by::Callable, iter) = groupunique(by, identity, iter)

function groupunique(by::Callable, f::Callable, iter)
    I = Core.Compiler.return_type(by, Tuple{eltype(iter)})
    T = Core.Compiler.return_type(f, Tuple{eltype(iter)})

    out = HashDictionary{I, HashIndices{T}}()
    for x in iter
        (hadtoken, token) = gettoken!(out, by(x))
        if hadtoken
            set!(gettokenvalue(out, token), f(x))
        else
            tmp = HashIndices{T}()
            set!(tmp, f(x))
            settokenvalue!(out, token, tmp)
        end
    end

    return out
end

groupfirst(iter) = groupfirst(identity, iter)

groupfirst(by::Callable, iter) = groupfirst(by, identity, iter)

function groupfirst(by::Callable, f::Callable, iter)
    I = Core.Compiler.return_type(by, Tuple{eltype(iter)})
    T = Core.Compiler.return_type(f, Tuple{eltype(iter)})

    out = HashDictionary{I, T}()
    for x in iter
        (hadtoken, token) = gettoken!(out, by(x))
        if !hadtoken
            settokenvalue!(out, token, f(x))
        end
    end

    return out
end

grouplast(iter) = grouplast(identity, iter)

grouplast(by::Callable, iter) = grouplast(by, identity, iter)

function grouplast(by::Callable, f::Callable, iter)
    I = Core.Compiler.return_type(by, Tuple{eltype(iter)})
    T = Core.Compiler.return_type(f, Tuple{eltype(iter)})

    out = HashDictionary{I, T}()
    for x in iter
        set!(out, by(x), f(x))
    end

    return out
end

grouponly(iter) = grouponly(identity, iter)

grouponly(by::Callable, iter) = grouponly(by, identity, iter)

function grouponly(by::Callable, f::Callable, iter)
    I = Core.Compiler.return_type(by, Tuple{eltype(iter)})
    T = Core.Compiler.return_type(f, Tuple{eltype(iter)})

    out = HashDictionary{I, T}()
    for x in iter
        insert!(out, by(x), f(x))
    end

    return out
end

groupcount(iter) = groupcount(identity, iter)

function groupcount(by::Callable, iter)
    I = Core.Compiler.return_type(by, Tuple{eltype(iter)})
    
    out = HashDictionary{I, Int}()
    for x in iter
        (hadtoken, token) = gettoken!(out, by(x))
        if hadtoken
            settokenvalue!(out, token, gettokenvalue(out, token) + 1)
        else
            settokenvalue!(out, token, 1)
        end
    end

    return out
end

groupreduce(by::Callable, op::Callable, iter) = groupreduce(by, identity, op, iter)

groupreduce(by, f, op, iter1, iter2, iters...; kw...) = groupreduce((x -> by(x...)), (x -> f(x...)), op, zip(iter1, iter2, iters...); kw...)

function groupreduce(by::Callable, f::Callable, op::Callable, iter; kw...)
    I = Core.Compiler.return_type(by, Tuple{eltype(iter)})
    T = Core.Compiler.return_type(f, Tuple{eltype(iter)})
    nt = kw.data
    
    out = HashDictionary{I, T}()
    for x in iter
        (hadtoken, token) = gettoken!(out, by(x))
        if hadtoken
            settokenvalue!(out, token, op(gettokenvalue(out, token), f(x)))
        else
            if nt isa NamedTuple{()}
                settokenvalue!(out, token, f(x))
            elseif nt isa NamedTuple{(:init,)}
                settokenvalue!(out, token, op(nt.init, f(x)))
            else
                throw(ArgumentError("groupreduce doesn't support these keyword arguments: $(setdiff(keys(nt), (:init,)))"))
            end
        end
    end

    return out
end

groupsum(iter) = groupsum(identity, iter)
groupsum(by, iter) = groupsum(by, identity, iter)
groupsum(by, f, iter) = groupreduce(by, f, +, iter)

groupprod(iter) = groupprod(identity, iter)
groupprod(by, iter) = groupprod(by, identity, iter)
groupprod(by, f, iter) = groupreduce(by, f, *, iter)













"""
    groupinds(by, iter...)

Sorts the indices `i` of `iter` into groups labeled by `by(iter[i])`. If multiple
collections (with matching indices) are provided, the groups are formed elementwise.

# Example

```jldoctest
julia> groupinds(iseven, [3,4,2,6,5,8])
Dict{Bool,Array{Int64,1}} with 2 entries:
  false => [1, 5]
  true  => [2, 3, 4, 6]
```
"""
function groupinds(by, iter)
    T = eltype(iter)
    K = promote_op(by, T)
    inds = keys(iter)
    V = eltype(inds)

    out = Dict{K, Vector{V}}()
    for i ∈ inds
        @inbounds x = iter[i]
        key = by(x)
        push!(get!(Vector{V}, out, key), i)
    end
    return out
end

groupinds(iter) = groupinds(identity, iter)

function groupinds(by, a::AbstractArray)
    _groupinds(mapview(by, a))
end

function _groupinds(a::AbstractArray)
    K = eltype(a)
    inds = keys(a)
    V = eltype(inds)

    out = Dict{K, Vector{V}}()
    @inbounds for i ∈ inds
        x = a[i]
        push!(get!(Vector{V}, out, x), i)
    end
    return out
end

# Semi-lazy grouping container
struct Groups{K, V, T, Inds} <: AbstractDict{K, V}
    parent::T
    inds::Inds
end

Base.keys(g::Groups) = keys(g.inds)
Base.@propagate_inbounds function Base.getindex(g::Groups, k)
    inds = g.inds[k]
    return view(g.parent, inds)
end
Base.length(g::Groups) = length(keys(g))

function Base.iterate(g::Groups, state...)
    i = iterate(g.inds, state...)
    if i === nothing
        return nothing
    else
        ((key, inds), newstate) = i
        return (key => @inbounds(g.parent[inds]), newstate)
    end
end


"""
    groupview(by, iter)

Like `group`, but each grouping is a view of the input collection `iter`.

# Example

```jldoctest
julia> v = [3,4,2,6,5,8]
6-element Array{Int64,1}:
 3
 4
 2
 6
 5
 8

julia> groups = groupview(iseven, v)
SAC.Groups{Bool,Any,Array{Int64,1},Dict{Bool,Array{Int64,1}}} with 2 entries:
  false => [3, 5]
  true  => [4, 2, 6, 8]

julia> groups[false][:] = 99
99

julia> v
6-element Array{Int64,1}:
 99
  4
  2
  6
 99
  8
```
"""
function groupview(by, iter)
    inds = groupinds(by, iter)
    T = typeof(iter)
    V = promote_op(view, T, eltype(inds))
    return Groups{keytype(inds), V, T, typeof(inds)}(iter, inds)
end

groupview(iter) = groupview(identity, iter)

"""
    groupreduce(by, f, op, iter...; [init])

Applies a `mapreduce`-like operation on the groupings labeled by passing the elements of
`iter` through `by`. Mostly equivalent to `map(g -> reduce(op, g), group(by, f, iter))`,
but designed to be more efficient. If multiple collections (of the same length) are
provided, the transformations `by` and `f` occur elementwise.
"""
function groupreduce(by, f, op, iter; kw...)
    # TODO Do this inference-free, like comprehensions...
    nt = kw.data
    T = eltype(iter)
    K = promote_op(by, T)
    T2 = promote_op(f, T)
    V = promote_op(op, T2, T2)

    out = Dict{K, V}()
    for x ∈ iter
        key = by(x)
        dict_index = ht_keyindex2!(out, key)
        if dict_index > 0
            @inbounds out.vals[dict_index] = op(out.vals[dict_index], f(x))
        else
            if nt isa NamedTuple{()}
                Base._setindex!(out, convert(V, f(x)), key, -dict_index)
            elseif nt isa NamedTuple{(:init,)}
                Base._setindex!(out, convert(V, op(nt.init, f(x))), key, -dict_index)
            else
                throw(ArgumentError("groupreduce doesn't support the keyword arguments $(setdiff(keys(nt), (:init,)))"))
            end
        end
    end
    return out
end

groupreduce(by, f, op, iter1, iter2, iters...; kw...) = groupreduce((x -> by(x...)), (x -> f(x...)), op, zip(iter1, iter2, iters...); kw...)

"""
    groupreduce(by, op, iter; [init])

Like `groupreduce(by, identity, op, iter; init=init)`.

# Example

```jldoctest
julia> groupreduce(iseven, +, 1:10)
Dict{Bool,Int64} with 2 entries:
false => 25
true  => 30
```
"""
groupreduce(by, op, iter; kw...) = groupreduce(by, identity, op, iter; kw...)
groupreduce(op, iter; kw...) = groupreduce(identity, identity, op, iter; kw...)

# Special group operators

@deprecate grouplength(by, iter) groupcount(by, iter)
export grouplength

"""
    groupcount([by], iter)

Determine the number of elements of `iter` belonging to each group.
"""
groupcount(by, iter) = groupreduce(by, x->1, +, iter)
groupcount(iter) = groupcount(identity, iter) # A handy extension of `unique`

"""
    groupsum(by, [f], iter)

Sum the elements of `iter` belonging to different groups, optionally mapping by `f`.
"""
groupsum(by, iter) = groupreduce(by, identity, +, iter)
groupsum(by, f, iter) = groupreduce(by, f, +, iter)
groupsum(iter) = groupreduce(identity, identity, +, iter) # For consistency

"""
    groupprod(by, [f], iter)

Multiply the elements of `iter` belonging to different groups, optionally mapping by `f`.
"""
groupprod(by, iter) = groupreduce(by, identity, *, iter)
groupprod(by, f, iter) = groupreduce(by, f, *, iter)
groupprod(iter) = groupreduce(identity, identity, *, iter) # For consistency
=#