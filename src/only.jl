function only(iter)
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

function only(::Tuple{})
    throw(ArgumentError("Collection must have exactly one element (input is empty)"))
end
function only(t::Tuple{Any})
    return t[1]
end
function only(::NTuple{N,Any}) where N
    throw(ArgumentError("Collection must have exactly one element (input has $N elements)"))
end
