function single(iter)
    i = iterate(iter)
    if i === nothing
        throw(ArgumentError("Collection must have exactly one element (input is empty)"))
    end
    (out, state) = i
    if iterate(iter, state) === nothing
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
