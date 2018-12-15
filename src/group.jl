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
    _groupinds(Generator(by, a))
end

function _groupinds(a)
    K = @default_eltype(a)
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

struct LazyGroups{F, It}
    f::F
    it::It
end

"""
    group(by, it)

Sorts the elements `x` of the iterable `it` into groups labeled by `by(x)`,
transforming each element to `f(x)`.

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

julia> groups = collect(group(iseven, v))
Main.SplitApplyCombine.Groups{Bool,SubArray{Int64,1,Array{Int64,1},Tuple{Array{Int64,1}},false},Array{Int64,1},Dict{Bool,Array{Int64,1}}} with 2 entries:
  false => [3, 5]
  true  => [4, 2, 6, 8]

julia> groups[false][:] .= 99
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
group(f, it) = LazyGroups(f, it)

function collect(l::LazyGroups)
    by = l.f
    iter = l.it
    inds = groupinds(by, iter)
    V = promote_op(view, typeof(iter), valtype(inds))
    return Groups{keytype(inds), V, typeof(iter), typeof(inds)}(iter, inds)
end

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
groupreduce(by, op, iter; kw...) = groupreduce(by, identity, op, iter; kw...)
groupreduce(op, iter; kw...) = groupreduce(identity, identity, op, iter; kw...)

function collect(g::Generator{It, F}) where {It <: LazyGroups, F <: Reduce}
    iter = g.iter
    by = iter.f
    it = iter.it
    op = g.f.f
    groupreduce(by, identity, op, it)
end

function collect(g::Generator{It, F}) where {It <: LazyGroups, F <: typeof(count)}
    iter = g.iter
    groupreduce(iter.f, x->1, +, iter.it)
end
