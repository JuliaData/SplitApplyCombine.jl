"""
    mapmany(f, a...)

Like `map`, but `f(x)` for each `x ∈ a` will return an arbitrary number of values.

# Example

```jldoctest
julia> mapmany(x -> 1:x, [1,2,3])
6-element Array{Int64,1}:
 1
 1
 2
 1
 2
 3
```
"""
function mapmany(f, a)
    T = eltype(promote_op(f, eltype(a)))
    out = T[]
    for x ∈ a
        append!(out, f(x))
    end
    return out
end

mapmany(f, a, b, c...) = mapmany((x,y,z...)->f(x,y,z...), zip(a, b, c...))

"""
    flatten(a)

Takes a collection of collections `a` and returns a collection containing all the elements
of the subcollecitons of `a`. Equivalent to `mapmany(idenity, a)`.

# Example

julia> flatten([1:1, 1:2, 1:3])
6-element Array{Int64,1}:
 1
 1
 2
 1
 2
 3
"""
flatten(x) = mapmany(identity, x) 

# mapview for lazy map?