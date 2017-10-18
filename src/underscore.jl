function expand_underscores_!(ex)
    if ex === :_
        return true
    end
    if ex isa Expr
        if (ex.head == :call && ex.args[1] == :|>)
            map!(expand_underscores!, ex.args, ex.args)
            return false
        else
            return any(expand_underscores_!, ex.args)
        end
    else
        return false
    end
end


function expand_underscores!(ex)
    if expand_underscores_!(ex)
        return Expr(:->, :_, ex)
    else
        ex
    end
end

macro _(ex)
    esc(expand_underscores!(ex))
end
