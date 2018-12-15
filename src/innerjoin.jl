export Match
struct Match{Compare, LeftKey, RightKey}
    compare::Compare
    left_key::LeftKey
    right_key::RightKey
end

"""
    Match(; compare = isequal, key = identity, right_key = key)

When called on a pair, `compare` `key(pair[1])` with `right_key(pair[2])`. Enables
hashing optimzations when filtering a product.

```jldoctest
julia> import SplitApplyCombine

julia> Match(key = abs)((1, -1))
true

julia> collect(Iterators.filter(Match(key = iseven), product([1,2,3,4], [0,1,2])))
6-element Array{Tuple{Int64,Int64},1}:
 (1, 1)
 (2, 0)
 (2, 2)
 (3, 1)
 (4, 0)
 (4, 2)
"""
Match(; compare = isequal, key = identity, right_key = key) =
    Match(compare, key, right_key)

(m::Match)(t) = m.compare(m.left_key(t[1]), m.right_key(t[2]))

<<<<<<< HEAD
const InnerJoin = Filter{F, ProductIterator{Tuple{A1, A2}}} where {F <: Match, A1, A2}

collect(it::InnerJoin) = collect(Generator(identity, it))
function collect(g::Generator{I}) where I <: InnerJoin
    iter = g.iter
    f = g.f
    iterators = iter.itr.iterators
    flt = iter.flt
    left = iterators[1]
    right = iterators[2]
=======
const InnerJoin = Filter{F, I} where {F <: Match, I <: AbstractProduct}

collect(it::InnerJoin) = inner_join(identity, it.flt, iterators(it.itr)...)
function collect(g::Generator{I}) where I <: InnerJoin
    iter = g.iter
    inner_join(g.f, iter.flt, iterators(iter.itr)...)
end

function inner_join(f, flt::Match, left::AbstractArray, right::AbstractArray)
>>>>>>> restore previous code
    ProductEltype = Tuple{eltype(left), eltype(right)}
    # TODO Do this inference-free, like comprehensions...
    out = empty(left, promote_op(f, ProductEltype))
    innerjoin!(out, flt.left_key, flt.right_key, f, flt.compare, left, right)
end

function innerjoin!(out, lkey, rkey, f, ::typeof(isequal), left, right)
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
#  * Accessing arrays via indices and Generators should be similar in speed to the above
#  * We can specialize these methods on particular arrays - works well for TypedTables.Table
#    of AcceleratedArrays.AcceleratedArray

function innerjoin!(out, lkey, rkey, f, comparison, left::AbstractArray, right::AbstractArray)
    _innerjoin!(out, Generator(lkey, left), Generator(rkey, right), Generator(f, product(left, right)), comparison)
end

function innerjoin!(out, lkey, rkey, f, ::typeof(isequal), left::AbstractArray, right::AbstractArray)
    _innerjoin!(out, Generator(lkey, left), Generator(rkey, right), Generator(f, product(left, right)), isequal)
end

function _innerjoin!(out, l, r, v, comparison)
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

function _innerjoin!(l, r, v, ::typeof(isequal))
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
