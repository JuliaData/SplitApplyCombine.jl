<<<<<<< HEAD
=======
export Inferable
"""
    Inferable{F}

Mark an inferable function for optimizations.

```jldoctest
julia> using SplitApplyCombine

julia> Generator(Inferable(x -> x + 1), [1, 2])
2-element Main.SplitApplyCombine.MappedArray{Int64,1,getfield(Main.SplitApplyCombine, Symbol("##88#89")),Array{Int64,1}}:
 2
 3
```
"""
struct Inferable{F}
    f::F
end

struct MappedArray{T, N, F, A <: AbstractArray{<:Any, N}} <: AbstractArray{T, N}
	f::F
	iter::A
end

iter(a::MappedArray) = a.iter
size(a::MappedArray) = size(a.iter)
axes(a::MappedArray) = axes(a.iter)
IndexStyle(a::MappedArray) = IndexStyle(a.iter)
@propagate_inbounds getindex(a::MappedArray{T}, i::Int) where {T} = a.f(a.iter[i])::T
@propagate_inbounds getindex(a::MappedArray{T}, i::Int...) where {T} = a.f(a.iter[i...])::T

MappedArray(f, a::AbstractArray{T, N}) where {T, N} = MappedArray{promote_op(f, T), N, typeof(f), typeof(a)}(f, a)
Generator(i::Inferable, a::AbstractArray) = MappedArray(i.f, a)

const AbstractGenerator = Union{Generator, MappedArray}

>>>>>>> restore previous code
# piracy
keys(it::Generator) = keys(it.iter)
empty(it::Generator) = map(it.f, empty(it.iter))
@propagate_inbounds getindex(it::Generator, args...) = it.f(it.iter[args...])
<<<<<<< HEAD
@propagate_inbounds getindex(it::ProductIterator, args...) = 
=======
@propagate_inbounds getindex(it::ProductIterator, args...) =
>>>>>>> restore previous code
    getindex.(it.iterators, args)
