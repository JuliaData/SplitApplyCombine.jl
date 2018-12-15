# piracy
keys(it::Generator) = keys(it.iter)
empty(it::Generator) = map(it.f, empty(it.iter))
@propagate_inbounds getindex(it::Generator, args...) = it.f(it.iter[args...])
@propagate_inbounds getindex(it::ProductIterator, args...) = 
    getindex.(it.iterators, args)
