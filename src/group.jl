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
        push!(get!(()->Vector{V}(), out, key), f(x))
    end
    return out
end

group(by, f, iter1, iter2, iters...) = group((x -> by(x...)), (x -> f(x...)), zip(iter1, iter2, iters...))


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
        push!(get!(()->Vector{V}(), out, key), i)
    end
    return out
end

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
Base.start(g::Groups) = start(g.inds)
function Base.next(g::Groups, i)
    ((key, inds), i2) = next(g.inds, i)
    return (key => g.parent[inds], i2)
end
Base.done(g::Groups, i) = done(g.inds, i)


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

if VERSION < v"0.7-"
    """
        groupreduce(by, op, f, iter...; [init])

    Applies a `mapreduce`-like operation on the groupings labeled by passing the elements of
    `iter` through `by`. Mostly equivalent to `map(g -> reduce(op, v0, g), group(by, f, iter))`,
    but designed to be more efficient. If multiple collections (of the same length) are
    provided, the transformations `by` and `f` occur elementwise.
    """
    function groupreduce(by, op, f, iter; kw...)
        # TODO Do this inference-free, like comprehensions...
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
                if length(kw) == 0
                    Base._setindex!(out, convert(V, f(x)), key, -dict_index)
                elseif length(kw) == 1 && kw[1][1]== :init
                    Base._setindex!(out, convert(V, op(kw[1][2], f(x))), key, -dict_index)
                else
                    throw(ArgumentError("groupreduce doesn't support the keyword arguments $(setdiff(first.(kw), [:init,]))"))
                end
            end
        end
        return out
    end
else
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
