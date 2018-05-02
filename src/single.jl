function single(iter)
    i = start(iter)
    if done(iter, i)
        throw(ArgumentError("Collection must have exactly one element (input is empty)"))
    end
    (out, i) = next(iter, i)
    if done(iter, i)
        return out
    else
        throw(ArgumentError("Collection must have exactly one element (input contains more than one element)"))
    end
end

function single(::Tuple{})
    throw(ArgumentError("Collection must have exactly one element (input is empty)"))
end
function single(t::Tuple{Any})
    return t[1]
end
function single(::NTuple{N,Any}) where N
    throw(ArgumentError("Collection must have exactly one element (input has $N elements)"))
end

if VERSION < v"0.7-"
    single(x::Nullable) = get(x)
end