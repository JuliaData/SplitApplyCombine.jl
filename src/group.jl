"""
    group(by, iter)

Group the elements `x` of the iterable `iter` into groups labeled by `by(x)`.

# Example

```jldoctest
julia> group(iseven, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
Dict{Bool,Array{Int64,1}} with 2 entries:
  false => [1, 3, 5, 7, 9]
  true  => [2, 4, 6, 8, 10]
```
"""
group(by, iter) = group(by, identity, iter)

"""
    group(by, f, iter...)

Sorts the elements `x` of the iterable `iter` into groups labeled by `by(x)`,
transforming each element to `f(x)`. If multiple collections (of the same length)
are provided, the transformations occur elementwise.

# Example

```jldoctest
julia> group(iseven, x -> x ÷ 2, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
Dict{Bool,Array{Int64,1}} with 2 entries:
  false => [0, 1, 2, 3, 4]
  true  => [1, 2, 3, 4, 5]
```
"""
function group(by, f, iter)
    # TODO Do this inference-free, like comprehensions...
    T = eltype(iter)
    K = promote_op(by, T)
    V = promote_op(f, T)
    
    out = Dict{K, Vector{V}}()
    for x ∈ iter
        key = by(x)
        push!(get!(Vector{V}, out, key), f(x))
    end
    return out
end

group(by, f, iter1, iter2, iters...) = group((x -> by(x...)), (x -> f(x...)), zip(iter1, iter2, iters...))

# For arrays we follow a different algorithm
group(by, f, a::AbstractArray) = group2(mapview(by, a), mapview(f, a))

function group2(groups, values)
    # TODO: assert that keys(groups) match up to keys(values)
    V = eltype(values)
    out = Dict{eltype(groups), Vector{V}}()
    @inbounds for i ∈ keys(groups)
        group = groups[i]
        value = values[i]
        push!(get!(Vector{V}, out, group), value)
    end
    return out
end

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
    V = promote_op(view, iter, eltype(inds))
    return Groups{keytype(inds), V, typeof(iter), typeof(inds)}(iter, inds)
end

"""
    groupreduce(by, op, f, iter...; [init])

Applies a `mapreduce`-like operation on the groupings labeled by passing the elements of
`iter` through `by`. Mostly equivalent to `map(g -> reduce(op, v0, g), group(by, f, iter))`,
but designed to be more efficient. If multiple collections (of the same length) are
provided, the transformations `by` and `f` occur elementwise.
"""
function groupreduce(by, op, f, iter; kw...)
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

groupreduce(by, op, f, iter1, iter2, iters...; kw...) = groupreduce((x -> by(x...)), op, (x -> f(x...)), zip(iter1, iter2, iters...); kw...)

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
groupreduce(by, op, iter; kw...) = groupreduce(by, op, identity, iter; kw...)

# Special group operators

"""
    grouplength(by, iter)

Determine the number of elements of `iter` belonging to each group.
"""
grouplength(by, iter) = groupreduce(by, +, x->1, iter)

"""
    groupsum(by, [f], iter)

Sum the elements of `iter` belonging to different groups, optionally mapping by `f`.
"""
groupsum(by, iter) = groupreduce(by, +, identity, iter)
groupsum(by, f, iter) = groupreduce(by, +, f, iter)

"""
    groupprod(by, [f], iter)

Multiply the elements of `iter` belonging to different groups, optionally mapping by `f`.
"""
groupprod(by, iter) = groupreduce(by, *, identity, iter)
groupprod(by, f, iter) = groupreduce(by, *, f, iter)
