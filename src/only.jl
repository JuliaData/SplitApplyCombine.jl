function only(iter)
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

function only(::Tuple{})
    throw(ArgumentError("Collection must have exactly one element (input is empty)"))
end
function only(t::Tuple{Any})
    return t[1]
end
function only(::NTuple{N,Any}) where N
    throw(ArgumentError("Collection must have exactly one element (input has $N elements)"))
end
