# Really dumb variable name replacement macro.  Doesn't know about scopes or
# the gory details of any `Expr`s
function replace_var!(ex, varname, replacement)
    if ex isa Expr
        map!(e->replace_var!(e, varname, replacement), ex.args, ex.args)
        return ex
    elseif ex === varname
        return replacement
    else
        return ex
    end
end

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
        return replace_var!(Expr(:->, :_, ex), :_, gensym("_"))
    else
        ex
    end
end

"""
    @_ ex

Expand an expression containing underscore placeholders into a lambda.  The
lambda head is placed at the outermost scope, except where interrupted by `|>`
pipe operators.

# Examples

`data |> reduce(+,_)`  expands to  `data |> x->reduce(+,x)`

`data |> foo(bar(_))`  expands to  `data |> x->foo(bar(x))`

"""
macro _(ex)
    esc(expand_underscores!(ex))
end
