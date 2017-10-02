function only(iter)
    i = start(iter)
    if done(iter, i)
        throw(ArgumentError("Collection must have exactly one element (input was empty)"))
    end
    (out, i) = next(iter, i)
    if done(iter, i)
        return out
    else
        throw(ArgumentError("Collection must have exactly one element (input contained more than one element)"))
    end
end