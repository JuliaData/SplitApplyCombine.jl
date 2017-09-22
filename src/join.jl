# TODO simplified signatures

function join(left_key, right_key, out_f, comparison, left, right)
    # TODO Do this inference-free, like comprehensions...
    T = Base.promote_op(out_f, eltype(left), eltype(right))
    out = T[]
    for a ∈ left
        for b ∈ right
            if comparison(left_key(a), right_key(b))
                push!(out, out_f(a, b))
            end
        end
    end
    return out
end

# TODO specialized methods for comparisons: ==, isequal, <, isless, etc - via hashing and sorting strategies
