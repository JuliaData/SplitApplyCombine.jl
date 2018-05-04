# Split, apply, combine

*Strategies for nested data in Julia*

[![Build Status](https://travis-ci.org/JuliaData/SplitApplyCombine.jl.svg?branch=master)](https://travis-ci.org/JuliaData/SplitApplyCombine.jl)
[![Coverage Status](https://coveralls.io/repos/github/JuliaData/SplitApplyCombine.jl/badge.svg?branch=master)](https://coveralls.io/github/JuliaData/SplitApplyCombine.jl?branch=master)
[![codecov.io](http://codecov.io/github/JuliaData/SplitApplyCombine.jl/coverage.svg?branch=master)](http://codecov.io/github/JuliaData/SplitApplyCombine.jl?branch=master)

*SplitApplyCombine.jl* provides high-level, generic tools for manipulating data -
particularly focussing on data in nested containers. An emphasis is placed on ensuring
split-apply-combine strategies are easy to apply, and work reliably for arbitrary iterables
and in an optimized way with the data structures included in Julia's standard library.

The tools come in the form of high-level functions that operate on iterable or indexable
containers in an intuitive and simple way, extending Julia's in-built `map`, `reduce` and
`filter` commands to a wider range of operations. Just like these `Base` functions, the
functions here like `group` and `innerjoin` are able to be overloaded and optimized by users
and the maintainers of other packages for their own, custom data containers.

One side goal is to provide sufficient functionality to satisfy the need to manipulate
"relational" data (meaning tables and dataframes) with basic in-built Julia data containers
like `Vector`s of `NamedTuple`s and higher-level functions in a "standard" Julia style.
I am exploring this idea further in another package under development called
[MinimumViableTables](https://github.com/andyferris/MinimumViableTables.jl)), which adds
acceleration indexes but otherwise uses a generic interface.

## Quick start

You can install the package by typing
`Pkg.clone("https://github.com/JuliaData/SplitApplyCombine.jl")` at the REPL.

Below are some simple examples of how a select subset of the tools can be used to split,
manipulate, and combine data. A complete API reference is included at the end of this
README.

```julia
julia> using SplitApplyCombine

julia> single([3]) # return the one-and-only element of the input
3

julia> splitdims([1 2; 3 4]) # create nested arrays
2-element Array{Array{Int64,1},1}:
 [1, 3]
 [2, 4]

julia> combinedims([[1, 2], [3, 4]]) # flatten nested arrays
2×2 Array{Int64,2}:
 1  2
 3  4

julia> group(iseven, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]) # split elements into groups
Dict{Bool,Array{Int64,1}} with 2 entries:
  false => [1, 3, 5, 7, 9]
  true  => [2, 4, 6, 8, 10]

julia> groupreduce(iseven, +, 1:10) # like above, but performing reduction
Dict{Bool,Int64} with 2 entries:
  false => 25
  true  => 30

julia> innerjoin(iseven, iseven, tuple, [1,2,3,4], [0,1,2]) # combine two datasets - related to SQL `inner join`
6-element Array{Tuple{Int64,Int64},1}:
 (1, 1)
 (2, 0)
 (2, 2)
 (3, 1)
 (4, 0)
 (4, 2)

julia> leftgroupjoin(iseven, iseven, tuple, [1,2,3,4], [0,1,2]) # efficient groupings from two datasets
Dict{Bool,Array{Tuple{Int64,Int64},1}} with 2 entries:
  false => Tuple{Int64,Int64}[(1, 1), (3, 1)]
  true  => Tuple{Int64,Int64}[(2, 0), (2, 2), (4, 0), (4, 2)]
```

## Tabular data

The primary interface for manipulating tabular data is the *relational algebra*. A
*relation* is typically defined as an (unordered) collection of (unique) (named) tuples. 
If relations are collections of rows, and tables are to be viewed as relations, then I
suggest that tables should be viewed as collections of rows (and in particular they should
iterate rows and return an entire row from `getindex`, if defined).

While simple, this already allows quite a bit of relational algebra to occur. One can then
`filter` rows of a table, `map` rows of a table (to project, rename or create columns), and
use `zip` and `product` iterables for more complex operations. The goal below will be to
discuss functions which work well for general iterables *and* will be useful for a table
that iterates rows. As a prototype to keep in mind for this work, I consider an 
`AbstractVector{<:NamedTuple}` to be a good model of a table/dataframe. Specialized
packages may provide convenient macro-based DSLs, a greater range of functions, and
implementations that focus on things such as out-of-core or distributed computing, more
flexible acceleration indexing, etc. Here I'm only considering the basic, bare-bones API
that may be extended and built upon by other packages.

## Notes

This package is nascent and many of the APIs here should be considered "under development"
for the time being. Many of the functions so far are inspired by other systems, notably
LINQ. The package current supports Julia v0.6 and v0.7/v1.0. Contributions and ideas very
welcome.

# API reference

The package currently implements and exports `single`, `splitdims`, `splitdimsview`,
`combinedims`, `combinedimsview`, `mapmany`, `flatten`, `group`, `groupinds`, `groupview`,
`groupreduce`, `innerjoin` and `leftgroupjoin`, as well as the `@_` macro. Expect this list
to grow.

## Generic operations on collections

### `single(iter)`

Returns the single, one-and-only element of the collection `iter`. If it contains zero
elements or more than one element, an error is thrown.

#### Example:

```julia
julia> single([3])
3

julia> single([])
ERROR: ArgumentError: Collection must have exactly one element (input was empty)
Stacktrace:
 [1] single(::Array{Any,1}) at /home/ferris/.julia/v0.7/SAC/src/single.jl:4

julia> single([3, 10])
ERROR: ArgumentError: Collection must have exactly one element (input contained more than one element)
Stacktrace:
 [1] single(::Array{Int64,1}) at /home/ferris/.julia/v0.7/SAC/src/single.jl:10
```

### `splitdims(array, [dims])`

Split a multidimensional array into nested arrays of arrays, splitting the specified 
dimensions `dims` to the "outer" array, leaving the remaining dimension in the "inner"
array. By default, the last dimension is split into the outer array.

#### Examples:

```julia
julia> splitdims([1 2; 3 4])
2-element Array{Array{Int64,1},1}:
 [1, 3]
 [2, 4]

julia> splitdims([1 2; 3 4], 1)
2-element Array{Array{Int64,1},1}:
 [1, 2]
 [3, 4]
```

### `splitdimsview(array, [dims])`

Like `splitdimsview(array, dims)` except creating a lazy view of the nested struture.

### `combinedims(array)`

The inverse operation of `splitdims` - this will take a nested array of arrays, where 
each sub-array has the same dimensions, and combine them into a single, flattened array.

```julia
julia> combinedims([[1, 2], [3, 4]])
2×2 Array{Int64,2}:
 1  2
 3  4
```

### `combinedimsview(array)`

Like `combinedims(array)` except creating a lazy view of the flattened struture.

### `mapmany(f, iters...)`

Like `map`, but `f(x...)` for each `x ∈ zip(iters...)` may return an arbitrary number of 
values to insert into the output.

#### Example:

```julia
julia> mapmany(x -> 1:x, [1,2,3])
6-element Array{Int64,1}:
 1
 1
 2
 1
 2
 3
```

(Note that, semantically, `filter` could be thought of as a special case of `mapmany`.)

### `flatten(a)`

Takes a collection of collections `a` and returns a collection containing all the elements
of the subcollecitons of `a`. Equivalent to `mapmany(identity, a)`.

#### Example:

```julia
julia> flatten([1:1, 1:2, 1:3])
6-element Array{Int64,1}:
 1
 1
 2
 1
 2
 3
```

## Grouping

These operations help you split the elements of a collection according to an arbitrary
function which maps each element to a group key.

### `group(by, [f = identity], iter)`

Group the elements `x` of the iterable `iter` into groups labeled by `by(x)`, transforming
each element . The default implementation creates a `Dict` of `Vector`s, but of course a
table/dataframe package might extend this to return a suitable (nested) structure of
tables/dataframes.

Also a `group(by, f, iters...)` method exists for the case where multiple iterables of the
same length are provided.

#### Examples:
```julia
julia> group(iseven, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
Dict{Bool,Array{Int64,1}} with 2 entries:
  false => [1, 3, 5, 7, 9]
  true  => [2, 4, 6, 8, 10]

julia> group(iseven, x -> x ÷ 2, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
Dict{Bool,Array{Int64,1}} with 2 entries:
  false => [0, 1, 2, 3, 4]
  true  => [1, 2, 3, 4, 5]
```

### `groupinds(by, iter)`

For *indexable* collections `iter`, returns the indices/keys associated with each group.
Similar to `group`, it supports multiple collections (with identical indices/keys) via the
method `groupinds(by, iters...)`.

#### Example:

```julia
julia> groupinds(iseven, [3,4,2,6,5,8])
Dict{Bool,Array{Int64,1}} with 2 entries:
  false => [1, 5]
  true  => [2, 3, 4, 6]
```

### `groupview(by, iter)`

Similar to `group(by, iter)` but the grouped elements are a view of the original collection.
Uses `groupinds` to construct the appropriate container.

#### Example:

```julia
julia> v = [3,4,2,6,5,8]
6-element Array{Int64,1}:
 3
 4
 2
 6
 5
 8

julia> groups = groupview(iseven, v)
SAC.Groups{Bool,Any,Array{Int64,1},Dict{Bool,Array{Int64,1}}} with 2 entries:
  false => [3, 5]
  true  => [4, 2, 6, 8]

julia> groups[false][:] = 99
99

julia> v
6-element Array{Int64,1}:
 99
  4
  2
  6
 99
  8
```

### `groupreduce(by, [f = identity], op, [v0], iter...)`

Applies a `mapreduce`-like operation on the groupings labeled by passing the elements of
`iter` through `by`. Mostly equivalent to `map(g -> reduce(op, v0, g), group(by, f, iter))`,
but designed to be more efficient. If multiple collections (of the same length) are
provided, the transformations `by` and `f` occur elementwise.

#### Example:
```julia
julia> groupreduce(iseven, +, 1:10)
Dict{Bool,Int64} with 2 entries:
  false => 25
  true  => 30
```

## Joining

### `innerjoin([lkey = identity], [rkey = identity], [f = tuple], [comparison = isequal], left, right)`

*Note*: it might be more natural to call this function `join`, except it clashes with the
existing `Base.join` string operation.

Performs a relational-style join operation between iterables `left` and `right`, returning
a collection of elements `f(l, r)` for which `comparison(lkey(l), rkey(r))` is `true` where
`l ∈ left`, `r ∈ right.`

#### Example:

```julia
julia> innerjoin(iseven, iseven, tuple, ==, [1,2,3,4], [0,1,2])
6-element Array{Tuple{Int64,Int64},1}:
 (1, 1)
 (2, 0)
 (2, 2)
 (3, 1)
 (4, 0)
 (4, 2)
```

### `leftgroupjoin([lkey = identity], [rkey = identity], [f = tuple], [comparison = isequal], left, right)`

Creates a collection if groups labelled by `lkey(l)` where each group contains elements
`f(l, r)` which satisfy `comparison(lkey(l), rkey(r))`. If there rae no matches, the group
is still created (with an empty collection).

This operation shares similarities with an SQL left outer join, but is more similar to
LINQ's `GroupJoin`.

#### Example:

```julia
julia> leftgroupjoin(iseven, iseven, tuple, ==, [1,2,3,4], [0,1,2])
Dict{Bool,Array{Tuple{Int64,Int64},1}} with 2 entries:
  false => Tuple{Int64,Int64}[(1, 1), (3, 1)]
  true  => Tuple{Int64,Int64}[(2, 0), (2, 2), (4, 0), (4, 2)]
```

## Syntax and macros

### `@_` macro

This adds the ability for piping to use the `_` to create anonymous functions quickly and
easily.

#### Example:

`@_ data |> reduce(+,_)` expands to `data |> x->reduce(+,x)`
