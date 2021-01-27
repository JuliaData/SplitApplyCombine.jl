"""
    group(iter)
    group(by::Union{Function, Type}, iter)
    group(by::Union{Function, Type}, f::Union{Function, Type}, iter...)

Return a dictionary of groups of elements `x` of the iterable `iter` into groups labeled by
`by(x)`, transforming each element to `f(x)`, where `by` and `f` default to the `identity`
function. If multiple collections (of the same length) are provided, the transformations
`by` and `f` occur elementwise.

# Example

```jldoctest
julia> group(iseven, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
Dictionary{Bool,Array{Int64,1}} with 2 entries:
 false │ [1, 3, 5, 7, 9]
 true  │ [2, 4, 6, 8, 10]

julia> group(iseven, x -> x ÷ 2, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
Dictionary{Bool,Array{Int64,1}} with 2 entries:
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

Return a dictionary of the elements of `values` grouped by the label inidcated by by the
matching element from `groups`.

# Example

```julia
julia> group([true,false,true,false,true], [1,2,3,4,5])
2-element Dictionary{Bool,Array{Int64,1}}
  true │ [1, 3, 5]
 false │ [2, 4]
```
"""
function group(groups, values)
    I = eltype(groups) # TODO EltypeUnknown
    T = eltype(values) # TODO EltypeUnknown

    out = Dictionary{I, Vector{T}}()
    @inbounds for (group, value) in zip(groups, values)
        push!(get!(Vector{T}, out, group), value)
    end

    return out
end

function group(groups::AbstractVector, values::AbstractVector)
    I = eltype(groups)
    T = eltype(values)

    if keys(groups) != keys(values)
        throw(DimensionMismatch("dimensions must match"))
    end

    VT = Core.Compiler.return_type(Base.emptymutable, Tuple{typeof(values)})
    out = Dictionary{I, VT}()
    @inbounds for i in keys(groups)
        group = groups[i]
        value = values[i]
        push!(get!(() -> Base.emptymutable(values), out, group), value)
    end

    return out
end

function group(groups::AbstractDictionary, values::AbstractDictionary)
    I = eltype(groups)
    T = eltype(values)

    out = Dictionary{I, Vector{T}}()

    if sharetokens(groups, values)
        @inbounds for token in tokens(groups)
            group = gettokenvalue(groups, token)
            value = gettokenvalue(values, token)
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

    out = Dictionary{I, T}()
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
groupsum(by::Callable, iter) = groupsum(by, identity, iter)
groupsum(by::Callable, f::Callable, iter) = groupreduce(by, f, +, iter)

"""
    groupprod(by, [f], iter)

Multiply the elements of `iter` belonging to different groups, optionally mapping by `f`.
"""
groupprod(iter) = groupprod(identity, iter)
groupprod(by::Callable, iter) = groupprod(by, identity, iter)
groupprod(by::Callable, f::Callable, iter) = groupreduce(by, f, *, iter)

"""
    groupcount([by], iter)

Determine the number of elements of `iter` belonging to each group.
"""
groupcount(by::Callable, iter) = groupreduce(by, x->1, +, iter)
groupcount(iter) = groupcount(identity, iter) # A handy extension of `unique`

"""
    groupfirst([by], [f], iter)

Find the first element of each grouping.
"""
groupfirst(iter) = groupreduce(identity, identity, former, iter)
groupfirst(by::Callable, iter) = groupreduce(by, identity, former, iter)
groupfirst(by::Callable, f::Callable, iter) = groupreduce(by, f, former, iter)
groupfirst(groups, values) = groupreduce(former, groups, values)

"""
    grouplast([by], [f], iter)

Find the last element of each grouping.
"""
grouplast(iter) = groupreduce(identity, identity, latter, iter)
grouplast(by::Callable, iter) = groupreduce(by, identity, latter, iter)
grouplast(by::Callable, f::Callable, iter) = groupreduce(by, f, latter, iter)
grouplast(groups, values) = groupreduce(latter, groups, values)


"""
    grouponly([by], [f], iter)

Return a dictionary mapping the unique elements `x` of iter grouped by `by(x)` with value
`f(x)`, where `by` and `f` default to the identity function.

This is an optimized equivalent of `only.(group(by, f, iter))` and is similar to
`Dictionary(by.(iter), f.(iter))`
"""
grouponly(iter) = grouponly(identity, iter)

grouponly(by::Callable, iter) = grouponly(by, identity, iter)

grouponly(by::Callable, f::Callable, iter) = grouponly(mapview(by, iter), mapview(f, iter))

"""
    grouponly(groups, values)

This is an optimized equivalent of `only.(group(groups, values))`.
"""
grouponly(groups, values) = Dictionary(groups, values)
# should make this more generic... if `groups` is an `AbstractIndices` we can use `similar`
# to generate the output...

"""
    groupunique([by], [f], iter)

Return a dictionary mapping the sets of elements `x` of iter grouped by `by(x)` with values
`f(x)`, where `by` and `f` default to the identity function.

This is similar to `unique.(group(by, f, iter))` but each subgroup is an `AbstractIndices`
of distinct values (rather than an `AbstractArray` with possibly repeated values).

# Example

```julia
julia> groupunique(iseven, [1,2,1,2,3])
2-element Dictionary{Bool,Indices{Int64}}
 false │ {2}
  true │ {1, 3}
```
"""
groupunique(iter) = groupunique(identity, iter)
groupunique(by::Callable, iter) = groupunique(by, identity, iter)
groupunique(by::Callable, f::Callable, iter) = groupunique(mapview(by, iter), mapview(f, iter))


"""
    groupunique(groups, values)

Collect the unique elements of `values` by the corresponding element of `groups`, returning
a dictinary of sets.

# Example

```julia
julia> groupunique([true,false,true,false,true], [1,2,1,2,3])
2-element Dictionary{Bool,Indices{Int64}}
  true │ {1, 3}
 false │ {2}
```
"""
function groupunique(groups, values)
    I = eltype(groups)
    T = eltype(values)

    out = Dictionary{I, Indices{T}}()
    for (group, value) in zip(groups, values)
        grouping = get!(Indices{T}, out, group)
        set!(grouping, value)
    end

    return out
end

@deprecate groupinds groupfind

"""
    groupfind([by], container)

Seperate the indices `i` of `container` into groups labeled by `by(container[i])`, where the
default value of `by` is `identity`.

# Example

```jldoctest
julia> groupfind(iseven, [3,4,2,6,5,8])
2-element Dictionary{Bool,Array{Int64,1}}
 false │ [1, 5]
  true │ [2, 3, 4, 6]
```
"""
groupfind(by::Callable, container) = groupfind(mapview(by, container))

function groupfind(container)
    I = eltype(container)
    T = keytype(container)

    out = Dictionary{I, Vector{T}}()
    @inbounds for i in keys(container)
        tmp = get!(Vector{T}, out, container[i])
        push!(tmp, i)
    end
    return out
end

function groupfind(inds::AbstractIndices)
    I = eltype(inds)
    T = keytype(inds)

    out = Dictionary{I, Vector{T}}()
    for i in inds
        tmp = get!(Vector{T}, out, i)
        push!(tmp, i)
    end
    return out
end

function groupfind(dict::AbstractDictionary)
    I = eltype(dict)
    T = keytype(dict)

    inds = keys(dict)
    out = Dictionary{I, Vector{T}}()
    @inbounds if istokenizable(dict)
        for t in tokens(dict)
            tmp = get!(Vector{T}, out, gettokenvalue(dict, t))
            push!(tmp, gettokenvalue(inds, t))
        end
    else
        for i in inds
            tmp = get!(Vector{T}, out, dict[i])
            push!(tmp, i)
        end
    end
    return out
end

# Semi-lazy grouping container (TODO docstring)
struct GroupDictionary{I, T, Parent, Inds <: AbstractDictionary{I}} <: AbstractDictionary{I, T}
    parent::Parent
    inds::Inds
end

Base.parent(g::GroupDictionary) = getfield(g, :parent)
_inds(g::GroupDictionary) = getfield(g, :inds)
Base.keys(g::GroupDictionary) = keys(_inds(g))

Base.isassigned(g::GroupDictionary{I}, k::I) where {I} = isassigned(_inds(g), k)
Base.@propagate_inbounds function Base.getindex(g::GroupDictionary{I}, i::I) where {I}
    inds = _inds(g)[i]
    return view(parent(g), inds)
end

Dictionaries.tokentype(g::GroupDictionary) = tokentype(_inds(g))
@propagate_inbounds Dictionaries.gettoken(g::GroupDictionary{I}, i::I) where {I} = gettoken(_inds(g), i)
Dictionaries.istokenassigned(g::GroupDictionary, t) = istokenassigned(_inds(g), t)
@propagate_inbounds function Dictionaries.gettokenvalue(g::GroupDictionary, t)
    inds = gettokenvalue(_inds(g), t)
    return view(parent(g), inds)
end

"""
    groupview([by], container)

Like `group`, but each grouping is a `view` of the indexable input `container`.

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
2-element GroupDictionary{Bool,SubArray{Int64,1,Array{Int64,1},Tuple{Array{Int64,1}},false},Array{Int64,1},Dictionary{Bool,Array{Int64,1}}}
 false │ [3, 5]
  true │ [4, 2, 6, 8]

julia> groups[false] .= 99  # set all the odd values to 99
2-element view(::Array{Int64,1}, [1, 5]) with eltype Int64:
 99
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
groupview(container) = groupview(identity, container)
function groupview(by::Callable, container)
    inds = groupfind(by, container)
    T = typeof(container)
    V = Core.Compiler.return_type(view, Tuple{T, eltype(inds)})
    return GroupDictionary{keytype(inds), V, T, typeof(inds)}(container, inds)
end
