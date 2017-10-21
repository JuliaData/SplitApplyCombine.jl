default_combine(x, y) = y

merge!(out, a) = merge!(default_combine, out, a)
merge!(combine, out, a, b, others...) = merge!(merge!(combine, out, a), combine, b, others...)

function merge!(combine, out, a)
    for (k, v) ∈ pairs(a)
        if haskey(out, k)
            out[k] = combine(out[k], v)
        else
            out[k] = v
        end
    end
    return out
end

merge(a, b) = merge(default_combine, a, b)
merge(combine, a, b, c, others...) = merge(combine, merge(combine, a, b), c, others...)

function merge(combine, a, b)
    # TODO possibly make this work for different eltype, keytype of b, or immutable a, etc
    out = copy(a)
    merge!(combine, out, b)
    return out
end

merge(combine, a::Number, b::Number) = combine(a, b)

function merge(::typeof(default_combine), a::Base.OneTo, b::Base.OneTo)
    return Base.OneTo(max(last(a), last(b)))
end

function merge(::typeof(default_combine), a::AbstractVector, b::AbstractVector)
    if keys(a) ⊆ keys(b)
        return b
    else
        out = similar(a, promote_type(eltype(a), eltype(b)), merge(keys(a), keys(b)))
        out[keys(a)] = a
        out[keys(b)] = b
    end
    return out
end

function merge(::typeof(default_combine), a::Tuple, b::Tuple)
    # TODO this sucks...
    if length(a) <= length(b)
        return b
    else
        return ntuple(i -> i <= length(b) ? b[i] : a[i], a, b)
    end
end