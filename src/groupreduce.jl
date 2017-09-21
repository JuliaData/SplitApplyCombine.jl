"""
    groupreduce(by, op, iter)

Like `groupreduce(by, identity, op, iter)`.

# Example

```jldoctest
julia> groupreduce(iseven, +, 1:10)
Dict{Bool,Int64} with 2 entries:
  false => 25
  true  => 30
```
"""
groupreduce(by, op, iter) = groupreduce(by, identity, op, iter)

"""
    groupreduce(by, f, op, iter)

Like `groupreduce(by, f, op, v0, iter)`, except the reductions are started with the first
element in the group rather than `v0`.
"""
function groupreduce(by, f, op, iter)
    # TODO Do this inference-free, like comprehensions...
    T = eltype(iter)
    K = Base.promote_op(by, T)
    T2 = Base.promote_op(f, T)
    V = Base.promote_op(op, T2, T2)
    
    out = Dict{K, V}()
    for x ∈ iter
        key = by(x)
        if haskey(out, key)
            out[key] = op(out[key], f(x))
        else
            out[key] = convert(V, f(x))
        end
    end
    return out
end

"""
    groupreduce(by, f, op, v0, iter)

Applies a `mapreduce`-like operation on the groupings labeled by passing the elements of
`iter` through `by`. Mostly equivalent to `map(g -> reduce(op, v0, g), group(by, f, iter))`,
but designed to be more efficient.
"""
function groupreduce(by, f, op, v0, iter)
    # TODO Do this inference-free, like comprehensions...
    T = eltype(iter)
    K = Base.promote_op(by, T)
    T2 = Base.promote_op(f, T)
    V = Base.promote_op(op, T2, T2)
    
    out = Dict{K, V}()
    for x ∈ iter
        key = by(x)
        if haskey(out, key)
            out[key] = op(out[key], f(x))
        else
            out[key] = convert(V, op(v0, f(x)))
        end
    end
    return out
end