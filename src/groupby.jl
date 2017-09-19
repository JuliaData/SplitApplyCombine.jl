"""
    groupby(by, iter)

Sorts the elements `x` of the iterable `iter` into groups labeled by `by(iter)`.

# Example

```jldoctest
julia> groupby(iseven, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
Dict{Bool,Array{Int64,1}} with 2 entries:
  false => [1, 3, 5, 7, 9]
  true  => [2, 4, 6, 8, 10]
```
"""
groupby(by, iter) = groupby(by, identity, iter)

"""
    groupby(by, iter)

Sorts the elements `x` of the iterable `iter` into groups labeled by `by(iter)`,
transforming each element to `f(x)`.

# Example

```jldoctest
julia> groupby(iseven, x -> x ÷ 2, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
Dict{Bool,Array{Int64,1}} with 2 entries:
  false => [0, 1, 2, 3, 4]
  true  => [1, 2, 3, 4, 5]
```
"""
function groupby(by, f, iter)
    # TODO Do this inference-free, like comprehensions...
    T = eltype(iter)
    K = Base.promote_op(by, T)
    V = Base.promote_op(f, T)
    
    out = Dict{K, Vector{V}}()
    for x ∈ iter
        key = by(x)
        if haskey(out, key)
            push!(out[key], f(x))
        else
            out[key] = V[f(x)]
        end
    end
    return out
end