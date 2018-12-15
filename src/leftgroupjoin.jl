"""
    leftgroupjoin([f = tuple], m::Match, left, right)

Creates a collection if groups labelled by `m.left_key(l)` where each group contains elements
`f(l, r)` which satisfy `m.compare(m.left_key(l), m.right_key(r))`. If there are no matches, the group
is still created (with an empty collection).

This operation shares some similarities with an SQL left outer join.

### Example

```jldoctest
julia> leftgroupjoin(Match(key = iseven), [1,2,3,4], [0,1,2])
Dict{Bool,Array{Tuple{Int64,Int64},1}} with 2 entries:
  false => Tuple{Int64,Int64}[(1, 1), (3, 1)]
  true  => Tuple{Int64,Int64}[(2, 0), (2, 2), (4, 0), (4, 2)]
```
"""
leftgroupjoin(f, m::Match, left, right) =
    leftgroupjoin(m.left_key, m.right_key, f, m.compare, left, right)
leftgroupjoin(m::Match, left, right) = leftgroupjoin(tuple, m, left, right)

function leftgroupjoin(lkey, rkey, f, comparison, left, right)
    # The O(length(left)*length(right)) generic method when nothing about `comparison` is known

    # TODO Do this inference-free, like comprehensions...
    T = promote_op(f, eltype(left), eltype(right))
    K = promote_op(lkey, eltype(left))
    V = Vector{T}
    out = Dict{K, V}()
    for a ∈ left
        key = lkey(a)
        group = get!(() -> T[], out, key)
        for b ∈ right
            if comparison(lkey(a), rkey(b))
                push!(group, f(a, b))
            end
        end
    end
    return out
end

function leftgroupjoin(lkey, rkey, f, ::typeof(isequal), left, right)
    # isequal heralds a hash-based approach, roughly O(length(left) * log(length(right)))

    # TODO Do this inference-free, like comprehensions...
    T = promote_op(f, eltype(left), eltype(right))
    K = promote_op(rkey, eltype(right))
    V = eltype(right)
    dict = Dict{K,Vector{V}}() # maybe a different stategy if right is unique
    for b ∈ right
        key = rkey(b)
        push!(get!(()->Vector{V}(), dict, key), b)
    end

    K2 = promote_op(lkey, eltype(left))
    out = Dict{K2, Vector{T}}()
    for a ∈ left
        key = lkey(a)
        group = get!(() -> T[], out, key)
        dict_index = Base.ht_keyindex(dict, key)
        if dict_index > 0 # -1 if key not found
            for b ∈ dict.vals[dict_index]
                push!(group, f(a, b))
            end
        end
    end
    return out
end

function leftgroupjoin(lkey, rkey, f, ::typeof(isequal), left::AbstractArray, right::AbstractArray)
    # isequal heralds a hash-based approach, roughly O(length(left) * log(length(right)))

    # TODO Do this inference-free, like comprehensions...
    T = promote_op(f, eltype(left), eltype(right))
    K = promote_op(rkey, eltype(right))
    V = eltype(right)
    dict = Dict{K,Vector{V}}() # maybe a different stategy if right is unique
    for b ∈ right
        key = rkey(b)
        push!(get!(()->Vector{V}(), dict, key), b)
    end

    K2 = promote_op(lkey, eltype(left))
    out = Dict{K2, typeof(empty(left, T))}()
    for a ∈ left
        key = lkey(a)
        group = get!(() -> empty(left, T), out, key)
        dict_index = Base.ht_keyindex(dict, key)
        if dict_index > 0 # -1 if key not found
            for b ∈ dict.vals[dict_index]
                push!(group, f(a, b))
            end
        end
    end
    return out
end
