# Join works on collections of collections (e.g. a table is a collection of
# rows).

innerjoin(left, right) = innerjoin(identity, identity, left, right)
innerjoin(lkey::Callable, rkey::Callable, left, right) = innerjoin(lkey, rkey, merge, left, right)
innerjoin(lkey::Callable, rkey::Callable, f::Callable, left, right) = innerjoin(lkey, rkey, f, isequal, left, right)

const ⨝ = innerjoin

"""
    innerjoin(lkey, rkey, f, comparison, left, right)

Performs a relational-style join operation between iterables `left` and `right`, returning
a collection of elements `f(l, r)` for which `comparison(lkey(l), rkey(r))` is `true` where
`l ∈ left`, `r ∈ right.`

# Example

```jldoctest
julia> innerjoin(iseven, iseven, tuple, ==, [1,2,3,4], [0,1,2])
6-element Array{Tuple{Int64,Int64},1}:
 (1, 1)
 (2, 0)
 (2, 2)
 (3, 1)
 (4, 0)
 (4, 2)
```
"""
function innerjoin(lkey::Callable, rkey::Callable, f::Callable, comparison::Callable, left, right)
    # TODO Do this inference-free, like comprehensions...
    T = promote_op(f, eltype(left), eltype(right))
    out = empty(left, T)

    innerjoin!(out, lkey, rkey, f, comparison, left, right)
    return out
end

function innerjoin!(out, lkey::Callable, rkey::Callable, f::Callable, comparison::Callable, left, right)
    # The O(length(left)*length(right)) generic method when nothing about `comparison` is known
    for a ∈ left
        for b ∈ right
            if comparison(lkey(a), rkey(b))
                push!(out, f(a, b))
            end
        end
    end
    return out
end

function innerjoin!(out, lkey::Callable, rkey::Callable, f::Callable, ::typeof(isequal), left, right)
    # isequal heralds a hash-based approach, roughly O(length(left) * log(length(right)))

    K = promote_op(rkey, eltype(right))
    V = eltype(right)
    dict = Dict{K,Vector{V}}() # maybe a different stategy if right is unique
    for b ∈ right
        key = rkey(b)
        push!(get!(()->Vector{V}(), dict, key), b)
    end

    for a ∈ left
        key = lkey(a)
        dict_index = Base.ht_keyindex(dict, key)
        if dict_index > 0 # -1 if key not found
            for b ∈ dict.vals[dict_index]
                push!(out, f(a, b))
            end
        end
    end
    return out
end

# For arrays, the assumptions around the below are
#  * Accessing arrays via indices and mapviews should be similar in speed to the above
#  * We can specialize these methods on particular arrays - works well for TypedTables.Table
#    of AcceleratedArrays.AcceleratedArray

function innerjoin!(out, lkey::Callable, rkey::Callable, f::Callable, comparison::Callable, left::AbstractArray, right::AbstractArray)
    _innerjoin!(out, mapview(lkey, left), mapview(rkey, right), productview(f, left, right), comparison)
end

function innerjoin!(out, lkey::Callable, rkey::Callable, f::Callable, ::typeof(isequal), left::AbstractArray, right::AbstractArray)
    _innerjoin!(out, mapview(lkey, left), mapview(rkey, right), productview(f, left, right), isequal)
end

function _innerjoin!(out, l::AbstractArray, r::AbstractArray, v::AbstractArray, comparison::Callable)
    @boundscheck if (axes(l)..., axes(r)...) != axes(v)
        throw(DimensionMismatch("innerjoin arrays do not have matching dimensions"))
    end

    @inbounds for i_l in keys(l)
        for i_r in keys(r)
            if comparison(l[i_l], r[i_r])
                push!(out, v[Tuple(i_l)..., Tuple(i_r)...])
            end
        end
    end

    return out
end

function _innerjoin!(out, l::AbstractArray, r::AbstractArray, v::AbstractArray, ::typeof(isequal))
    @boundscheck if (axes(l)..., axes(r)...) != axes(v)
        throw(DimensionMismatch("innerjoin arrays do not have matching dimensions"))
    end

    rkeys = keys(r)
    V = eltype(rkeys)
    dict = Dict{eltype(r), Vector{V}}()
    @inbounds for i_r ∈ rkeys
        push!(get!(()->Vector{V}(), dict, r[i_r]), i_r)
    end

    @inbounds for i_l in keys(l)
        l_value = l[i_l]
        dict_index = Base.ht_keyindex(dict, l_value)
        if dict_index > 0 # -1 if key not found
            for i_r ∈ dict.vals[dict_index]
                push!(out, v[Tuple(i_l)..., Tuple(i_r)...])
            end
        end
    end

    return out
end


# TODO more specialized methods for comparisons: ==, <, isless, etc - via sorting strategies

# TODO perhaps a better version would be:
# function innerjoin(left, right; lkey = identity, rkey = identity, f = tuple, comparison = isequal)
#     ...
# end
