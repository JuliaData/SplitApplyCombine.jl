leftgroupjoin(left, right) = leftgroupjoin(identity, identity, left, right)
leftgroupjoin(lkey::Callable, rkey::Callable, left, right) = leftgroupjoin(lkey, rkey, merge, left, right)
leftgroupjoin(lkey::Callable, rkey::Callable, f::Callable, left, right) = leftgroupjoin(lkey, rkey, f, isequal, left, right)

"""
    leftgroupjoin(lkey, rkey, f, comparison, left, right)

Creates a collection if groups labelled by `lkey(l)` where each group contains elements
`f(l, r)` which satisfy `comparison(lkey(l), rkey(r))`. If there are no matches, the group
is still created (with an empty collection).

This operation shares some similarities with an SQL left outer join.

### Example

```jldoctest
julia> leftgroupjoin(iseven, iseven, tuple, ==, [1,2,3,4], [0,1,2])
HashDictionary{Bool,Array{Tuple{Int64,Int64},1}} with 2 entries:
  false │ Tuple{Int64,Int64}[(1, 1), (3, 1)]
  true  │ Tuple{Int64,Int64}[(2, 0), (2, 2), (4, 0), (4, 2)]
```
"""
function leftgroupjoin(lkey::Callable, rkey::Callable, f::Callable, comparison::Callable, left, right)
    # The O(length(left)*length(right)) generic method when nothing about `comparison` is known

    # TODO Do this inference-free, like comprehensions...
    T = Core.Compiler.return_type(f, Tuple{eltype(left), eltype(right)})
    K = Core.Compiler.return_type(lkey, Tuple{eltype(left)})
    V = Vector{T}
    out = HashDictionary{K, V}()
    for a ∈ left
        key = lkey(a)
        group = get!(V, out, key)
        for b ∈ right
            if comparison(key, rkey(b))
                push!(group, f(a, b))
            end
        end
    end
    return out
end

function leftgroupjoin(lkey::Callable, rkey::Callable, f::Callable, ::typeof(isequal), left, right)
    # isequal heralds a hash-based approach, roughly O(length(left) * log(length(right)))

    # TODO Do this inference-free, like comprehensions...
    T = Core.Compiler.return_type(f, Tuple{eltype(left), eltype(right)})
    K = Core.Compiler.return_type(rkey, Tuple{eltype(right)})
    V = eltype(right)
    dict = HashDictionary{K,Vector{V}}() # maybe a different stategy if right is unique
    for b ∈ right
        key = rkey(b)
        push!(get!(Vector{V}, dict, key), b)
    end

    K2 = Core.Compiler.return_type(lkey, Tuple{eltype(left)})
    out = HashDictionary{K2, Vector{T}}()
    for a ∈ left
        key = lkey(a)
        token = gettoken(out, key)
        group = get!(Vector{T}, out, key)
        (has_index, token) = gettoken(dict, key)
        if has_index
            for b ∈ gettokenvalue(dict, token)
                push!(group, f(a, b))
            end
        end
    end
    return out
end
