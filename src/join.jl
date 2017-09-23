# TODO simplified signatures

join(left, right) = join(identity, identity, left, right)
join(lkey, rkey, left, right) = join(lkey, rkey, tuple, left, right)
join(lkey, rkey, f, left, right) = join(lkey, rkey, f, isequal, left, right)

function join(lkey, rkey, f, comparison, left, right)
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

function join(lkey, rkey, f, ::typeof(isequal), left, right)
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
# function join(left, right; lkey = identity, rkey = identity, f = tuple, comparison = isequal)
#     ...
# end
