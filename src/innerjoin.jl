# TODO simplified signatures

innerjoin(left, right) = innerjoin(identity, identity, left, right)
innerjoin(lkey, rkey, left, right) = innerjoin(lkey, rkey, tuple, left, right)
innerjoin(lkey, rkey, f, left, right) = innerjoin(lkey, rkey, f, isequal, left, right)

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
function innerjoin(lkey, rkey, f, comparison, left, right)
    # The O(length(left)*length(right)) generic method when nothing about `comparison` is known

    # TODO Do this inference-free, like comprehensions...
    T = Base.promote_op(f, eltype(left), eltype(right))
    out = T[]
    for a ∈ left
        for b ∈ right
            if comparison(lkey(a), rkey(b))
                push!(out, f(a, b))
            end
        end
    end
    return out
end

function innerjoin(lkey, rkey, f, ::typeof(isequal), left, right)
    # isequal heralds a hash-based approach, roughly O(length(left) * log(length(right)))

    # TODO Do this inference-free, like comprehensions...
    T = Base.promote_op(f, eltype(left), eltype(right))
    K = Base.promote_op(rkey, eltype(right))
    V = eltype(right)
    dict = Dict{K,Vector{V}}() # maybe a different stategy if right is unique
    for b ∈ right
        key = rkey(b)
        push!(get!(()->Vector{V}(), dict, key), b)
    end

    out = T[]
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

# TODO more specialized methods for comparisons: ==, <, isless, etc - via sorting strategies

# TODO perhaps a better version would be:
# function innerjoin(left, right; lkey = identity, rkey = identity, f = tuple, comparison = isequal)
#     ...
# end
