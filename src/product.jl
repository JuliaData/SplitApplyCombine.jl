struct ProductArray{T, N, A <: AbstractArray, B <: AbstractArray} <: AbstractArray{T, N}
	a::A
	b::B
end

Base.IndexStyle(::Type{<:ProductArray}) = IndexCartesian()
Base.axes(p::ProductArray) = (axes(p.a)..., axes(p.b)...)
Base.size(p::ProductArray) = (size(p.a)..., size(p.b)...)
@propagate_inbounds function Base.getindex(p::ProductArray{T}, i::Int...) where {T}
	ndims_a = ndims(p.a)
	ndims_b = ndims(p.b)
	i_a = ntuple(j -> @inbounds(return i[j]), Val(ndims_a))
	i_b = ntuple(j -> @inbounds(return i[j + ndims_a]), Val(ndims_b))
	return (p.a[i_a...], p.b[i_b...])::T
end

function ProductArray(a::AbstractArray, b::AbstractArray)
	T = Tuple{eltype(a), eltype(b)}
	N = ndims(a) + ndims(b)
	return ProductArray{T, N, typeof(a), typeof(b)}(a, b)
end

product(a::AbstractArray, b::AbstractArray) = ProductArray(a, b)

const AbstractProduct = Union{ProductIterator, ProductArray}

iterators(p::ProductIterator) = p.iterators
iterators(p::ProductArray) = (p.a, p.b)
