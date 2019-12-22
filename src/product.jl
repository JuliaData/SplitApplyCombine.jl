"""
    product(f, a, b)

Takes the Cartesian outer product of two containers and evaluates `f` on all pairings of
elements. 

For example, if `a` and `b` are vectors, this returns a matrix `out` such that
`out[i,j] = f(a[i], b[j])` for `i in keys(a)` and `j in keys(b)`. See also `productview`.

# Example

```julia
julia> product(+, [1,2], [1,2,3])
2×3 Array{Int64,2}:
 2  3  4
 3  4  5
```
"""
function product(f::Callable, a, b)
	out = similar(a, promote_op(f, eltype(a), eltype(b)), (axes(a)..., axes(b)...))
	return product!(f, out, a, b)
end

@inline function product!(f::Callable, out, a, b)
	axes_a = axes(a)
	axes_b = axes(b)
	axes_out = axes(out)

	@boundscheck if axes_out != (axes_a..., axes_b...)
	    throw(DimensionMismatch("Output does not match input dimensions"))
	end

	@inbounds for i_a in CartesianIndices(axes_a)
		for i_b in CartesianIndices(axes_b)
			i_out = CartesianIndex(i_a.I..., i_b.I...)
			out[i_out] = f(a[i_a], b[i_b])
		end
	end

	return out
end

struct ProductArray{T, N, F, A <: AbstractArray, B <: AbstractArray} <: AbstractArray{T, N}
	f::F
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
	return p.f(p.a[i_a...], p.b[i_b...])::T
end

"""
    productview(f, a, b)

Return a view of a Cartesian product of `a` and `b` where the output elements are `f`
evaluated those of `a` and `b`. See also `product` and `ProductArray`

# Example

```julia
julia> productview(+, [1,2], [1,2,3])
2×3 ProductArray{Int64,2,typeof(+),Array{Int64,1},Array{Int64,1}}:
 2  3  4
 3  4  5
```
"""
function productview(f::Callable, a, b)
	T = promote_op(f, eltype(a), eltype(b))
	N = ndims(a) + ndims(b)
	return ProductArray{T, N, typeof(f), typeof(a), typeof(b)}(f, a, b)
end