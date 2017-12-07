# Split, apply, combine

[![Build Status](https://travis-ci.org/JuliaData/SplitApplyCombine.jl.svg?branch=master)](https://travis-ci.org/JuliaData/SplitApplyCombine.jl)
[![Coverage Status](https://coveralls.io/repos/github/JuliaData/SplitApplyCombine.jl/badge.svg?branch=master)](https://coveralls.io/github/JuliaData/SplitApplyCombine.jl?branch=master)
[![codecov.io](http://codecov.io/github/JuliaData/SplitApplyCombine.jl/coverage.svg?branch=master)](http://codecov.io/github/JuliaData/SplitApplyCombine.jl?branch=master)

This is a playground for exploring data manipulation functions in Julia - their
semantics, design, and functionality. A particular emphasis is placed on ensuring
split-apply-combine strategies are easy to apply, and work relatively optimally for
arbitrary iterables and data structures included in `Base`. 

This package currently consists of two products: the code, and this document. The code provides an
example implementation of some of the things discussed in this document. This document is
a place to organize thoughts on the data manipulation tools provided in `Base` Julia and
musings on where to go next.

## Motivation

Julia has proven itself as a techincal computing language with some outstanding attibutes.
I'm particularly attracted to its user productivity, execution speed and flexibity. Because
so much `AbstractArray` and linear algebra functionality is built into `Base`, along with
strong generic programming abilities and well thought-out APIs which can be extended from
diverse sets of arrays on GPUs, distributed computing, and down to tiny "static" arrays,
it is easy to perform complex calculations at the REPL or produce efficient, scalable HPC
code without too much effort.

Such a language also lends itself to performing data science - manipulating "data" of
different scales and extracting insights. It is common in this field (and computing more
broadly) to want to perform data manipulation operations on tabular data. However, as of
now, there is no built-in support for performing simple tabular joins, or grouping
operations, or many abstractions for split-apply-combine strategies in general. This might
not be a critical problem, as Julia is designed to be extended by packages (code in
packages is just as powerful as code in `Base`) - however, the package ecosystem at the
moment does not share an API, a type tree, or even much of a common design philosophy.

Currently, there is a broad effort to correct this, and make the data story in Julia
stronger and more cohesive. As someone who's been somewhat of an observer, and somewhat
of a participator, in the data space, I note that I constantly return to this observation:
the array story has been so successful because of `AbstractArray` and `LinAlg` and a set
of well-curated APIs that *work for both general iterables and arrays*. Generic programming
that works for tiny arrays and large arrays and gigantic arrays, works because of a clear
API with strong semantics that everyone adheres to. It's my belief that the data space
would benefit from the same - figuratively (not literally) an `AbstractTable` and `RelAlg`
(relational algebra) module. So I ask myself these two questions:

 * What APIs work for generic iterables that would also be useful for tabular data? Is
   there any call to contribute these to `Base`? Would it make sense to modify anything
   already existing in `Base`?
 * How should we interact with tabular data - from tiny data sets, to big data? Do we need
   an `AbstractTable`? What would its interface be, that enables the highest efficiency
   and high programmer productivity? Should we implement and share a pretty direct
   implementation of relational algebra, in analogy to `Base.LinAlg`?

This package is skewed towards the first question; other work focuses more on the second.
But in my opinion a successful end result will address both satisfactorily.

## Recent and upcoming changes

There are some particular changes posed for v0.7 which affect the design considerations
here.

 * The iteration scheme for `Associative` may move closer to that of `AbstractArray`.
   It is assumed that the iterations will only consist of the *values* of the dictionary,
   rather than key-value `Pair`s. The `pairs(dict)` function will return an iterable over
   key-value pairs.

 * `NamedTuple` and other potential changes like `getfield` overloading, anonymous structs,
   and/or inter-procedural constant propagation in inference, will enable simple row-based
   and columb-based storage of strongly typed tables. For example, a `Vector{<:NamedTuple}`
   could pose as a basic, row-based, in-memory table suitable for REPL work.

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
`AbstractVector{<:NamedTuple}` to be a good model of an `AbstractTable`. Specialized
packages may provide convenient macro-based DSLs, a greater range of functions, and
implementations that focus on things such as out-of-core or distributed computing, more
flexible acceleration indexing, etc. Here I'm only considering the basic, bare-bones API
that may be extended and built upon by other packages.

# API

The package currently implements and exports `only`, `mapmany`, `flatten`, `group`,
`groupinds`, `groupview`, `groupreduce`, `innerjoin` and `leftgroupjoin`, as well as the 
`@_` macro. Expect this list
to grow.

## Generic operations on collections

### `only(iter)`

Returns the only element of the collection `iter`. If it contains zero elements or more than
one element, an error is thrown.

#### Example:

```julia
julia> only([3])
3

julia> only([])
ERROR: ArgumentError: Collection must have exactly one element (input was empty)
Stacktrace:
 [1] only(::Array{Any,1}) at /home/ferris/.julia/v0.7/SAC/src/only.jl:4

julia> only([3, 10])
ERROR: ArgumentError: Collection must have exactly one element (input contained more than one element)
Stacktrace:
 [1] only(::Array{Int64,1}) at /home/ferris/.julia/v0.7/SAC/src/only.jl:10
```

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

#### Example

```julia
julia> groupinds(iseven, [3,4,2,6,5,8])
Dict{Bool,Array{Int64,1}} with 2 entries:
  false => [1, 5]
  true  => [2, 3, 4, 6]
```

### `groupview(by, iter)`

Similar to `group(by, iter)` but the grouped elements are a view of the original collection.
Uses `groupinds` to construct the appropriate container.

#### Example

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

#### Example"

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

## TODO

The API could be improved by providing default join comparison and mapping operations which
can be extended by table/dataframe packages (also, `NamedTuple`s) to perform a natural join
by automatically linking fields with matching names. In this case, it would be perfectly
reasonable to use the `⨝` operator for `a ⨝ b` being `innerjoin(a, b)` for tables `a` and 
`b` with appropriately named columns.

Using keyword arguments, it would be be nice to be able to filter out entire groups or
elements of groups in `group`, `groupinds`, `groupview` and `groupreduce`. This would be
more efficient than collecting all the groups and filtering afterwards.

Perhaps we want to either add the ability for `groupview` to have a mapping function `f`, or
else remove this from `group`, since this seems somewhat inconsistent.

# Improving Julia syntax and APIs

Here is some discussion of possible ways to make the data APIs in `Base` easier to interact
with.

### `join`

The `Base.join` function is currently taken by string joins, and strings are iterable and so
should participate in the "data" join as a colleciton of characters. This
presents a rather unfortnate naming clash, since `join` or `Join` is common in a wide
variety of languages to mean these two different operations (which isn't great for Julia's
system of semantically distinct functions). I haven't found an alternative name for the 
string operation... however I do note that the current `Base.join` on strings is a
generalization of a concatenation operation with seperators added between, which might be a
useful operation for generic iterables, and might take a name related to concatenation
instead.

Here I've exported `innerjoin` to avoid clashing, which is a reasonably common (but longer)
name for this operation.

### Reductions

We currently have roughly the following methods

 * `reduce(op, iter)`
 * `reduce(op, v0, iter)`
 * `mapreduce(f, op, iter)`
 * `mapreduce(f, op, v0, iter)`
 * `mapreduce(f, op, v0, iters...)`

Unfortunately, these do not cover all common "reductions" and "agregations" since
there is no function to apply at the end of the reduction (as included in LINQ, etc). Take
for example `mean` which needs to divide the `sum` by the `length`, which could be written
as:

```julia
function mean(iter)
    (sum, n) = mapreduce(x -> (x, 1), (a,b) -> (a[1]+b[1], a[2]+b[2]), iter)
    return sum / n
end
```

However, it would make sense to include the "final" function (dividing by the number of
elements, in the above) in the `reduce` and `mapreduce` APIs with a default value of
`identity`. However, at this stage it becomes unwieldly without using keyword arguments.
Fortunately, in v1.0 we can begin to use keyword arguments and might consider a "simpler"
API:

 * `reduce(op, iter; v0 = Default(), final = identity)`
 * `mapreduce(f, op, iter; v0 = Default(), final = identity)`

Here `Default()` would be some singleton to allow us to deal with reductions that start
with or without a `v0`. Taking this to extremes, we may want to put all the functions in
as keyword arguments (the default values are not thought out, rather chosen at random):

 * `map(iters...; f = identity)`
 * `reduce(iter; op = tuple, v0 = Default(), final = identity)`
 * `mapreduce(iters...; f = identity, op = tuple, v0 = Default(), final = identity)`
 * `group(iters...; by = identity, f = identity)`
 * `groupreduce(iters...; by = identity, f = identity, op = tuple, v0 = Default(), final = identity)`
 * `join(left, right; lkey = identity, rkey = identity, f = tuple, comparison = isequal)`
 * `filter(iter; predicate = identity)`

(probably the default value of `op` should throw an error upon call, reminding the user to
explicitly specify `op`). Note that the above standardize where the containers sit, as
positional arguments, and share the same keyword names where they overlap. One could
imagine removing `mapreduce` and instead putting an `f` keyword argument into `reduce` with
default as `identity`, as well as adding a filter to reductions, a mapping to `filter`,
etc.

While v1.0 will solve the speed problems of using keyword arguments, there are still a few
syntactic issues that make working with keyword arguments a bit more difficult than
necessary. Particularly, I propose improvements to `do` syntax and to piping, below.

### `do` syntax generalization

The `do` syntax allows one to specify a closure such that it appears in code in the order
that it is executed. However, it is (a) frequently confusing to newcomers and (b) is very
picky about where the function is injected. For example, we can't specify `op` in
`mapreduce` via the `do` syntax.

I propose to use a `with` keyboard that enables more transparency, flexibility, and reads
better as English. We begin with the current syntax:

```julia
map(iter) do x
    x + 1
end
```

I see the following as more natural, using `with` which is much like `let` but working in
the opposite order:

```julia
map(f, iter) with f = function (x)
   x + 1
end
```

which lowers to
```julia
let f = function (x); x + 1; end;
    map(f, iter)
end
```

Now we can use `with` to inject `f` anywhere in the expression on the left, including in
the place of keyword arguments or a positional argument other than the first. One could
alternatively imagine a `with` that creates a block instead

```julia
mapreduce(f, op, iter) with
    a = 2
    f(x) = a*x
    op(x,y) = (x+y)^a
end
```

which lowers to

```julia
let a=2, f(x) = a*x, op(x,y) = (x+y)^a
    mapreduce(f, op, iter)
end
```

While investigating this, we also found that `let` doesn't support the standard long
function form as assigment, as in we should allow `let function f(x); ...; end; ....; end`
be an equivalent form for `let f = function (x); ...; end; ....; end`.

### Piping

Note that this has been implemented here under the `@_` macro.

Piping currently only works "natively" for single argument functions, but many data methods
contain multiple slots for data and functions to appear. If a multi-function argument is
required, the user is forced to write an extra anonymous using `->` a few characters after
typing `|>`, which seems to me to be a jarring experience. I propose that `|>`
automatically creataes a function of `_`, which is the output from the previous statement.
Compare the following:

```julia
data |> x -> reduce(+, x) |> iseven
data |> reduce(+, _) |> iseven(_)
```
I prefer the latter because (a) it's quicker to express the `reduce` operation, and (b) the
more verbose `iseven` statement visually looks like a function call, distinct from the
`data` on the left, and (c) the `|>` operators visually seperate better without `->`
appearing in-between.

Some functions may return multiple outputs. Consider using `eig` to get the determinant of
a matrix:
```julia
matrix |> eig |> x -> prod(x[1])
matrix |> eig(_) |> prod(_[1])
```

Data operations may be particularly complex and benifit from this syntax.
```julia
table1 |> x -> join((r1,r2 -> (r1...,r2...), x, table2) |> x -> group(r->r.col, x) |> length
table1 |> join((r1,r2 -> (r1...,r2...), _, table2) |> group(r->r.col, _) |> length(_)
```

## Examples

Hopefully we can motivate all of the above by writing some interesting data manipulations
in what is imagined to be included in an upgraded version of `Base`. These examples use
tuple rows with overly expressive variable names - it would be better to use named tuples
and simpler table names.

Here's a `innerjoin` example, adapted from the *DataFrames.jl* docs:

```julia
julia> using SplitApplyCombine

julia> employee_id_name = [(20, "John Doe"), (40, "Jane Doe")]
2-element Array{Tuple{Int64,String},1}:
 (20, "John Doe")
 (40, "Jane Doe")

julia> employee_id_job = [(20, "Lawyer"), (40, "Doctor")]
2-element Array{Tuple{Int64,String},1}:
 (20, "Lawyer")
 (40, "Doctor")

julia> innerjoin(id_name -> id_name[1], id_job -> id_job[1], (id_name, id_job) -> (id_name[2], id_job[2]), employee_id_name, employee_id_job) 
2-element Array{Tuple{String,String},1}:
 ("John Doe", "Lawyer")
 ("Jane Doe", "Doctor")
```

In the future, it would be much more readable to use `NamedTuple`. Here is an
example of possible v1.0 syntax:
```julia
employees = [(id = 20, name = "John Doe"), (id = 40, "Jane Doe")]
jobs = [(id = 20, job = "Lawyer"), (id = 40, job = "Doctor")]
innerjoin(l -> l.id, r = r.id, (l,r) -> (name = l.name, job = r.job), employees, jobs)
```

Moving on, this is a `group` example with `Tuple`s, adapted from MSDN LINQ C# documentation:

```julia
julia> pet_name_age = [("Barley", 8), ("Boots", 4), ("Whiskers", 1), ("Daisy", 4)]
4-element Array{Tuple{String,Int64},1}:
 ("Barley", 8)  
 ("Boots", 4)   
 ("Whiskers", 1)
 ("Daisy", 4)   

julia> group(name_age -> name_age[2], name_age -> name_age[1], pet_name_age)
Dict{Int64,Array{String,1}} with 3 entries:
  4 => ["Boots", "Daisy"]
  8 => ["Barley"]
  1 => ["Whiskers"]
```

And finally, here is an example using the `leftgroupjoin` function (perhaps a group key
distinct from join key would be benificial?).

```julia
julia> custid_name = [(1, "Bob"), (2, "Jane"), (3, "David")]
3-element Array{Tuple{Int64,String},1}:
 (1, "Bob")  
 (2, "Jane") 
 (3, "David")

julia> orderid_custid_product_price = [(1, 2, "Shoes", 99.99), (2, 1, "Shirt", 50.0), (3, 2, "Dress", 60.0)]
3-element Array{Tuple{Int64,Int64,String,Float64},1}:
 (1, 2, "Shoes", 99.99)
 (2, 1, "Shirt", 50.0) 
 (3, 2, "Dress", 60.0) 

julia> leftgroupjoin(x->x[1], x->x[2], (x,y)->(y[3], y[4]), custid_name, orderid_custid_product_price)
Dict{Int64,Array{Tuple{String,Float64},1}} with 3 entries:
  2 => Tuple{String,Float64}[("Shoes", 99.99), ("Dress", 60.0)]
  3 => Tuple{String,Float64}[]
  1 => Tuple{String,Float64}[("Shirt", 50.0)]
```

In all cases, it would be much more readable to use `NamedTuple`, and packages like
*DataFrames* would let you select columns and so-on with greater ease rather than creating
anonymous functions.


## Things in LINQ that aren't in Julia

LINQ provides a set of methods for classes that fulfill the `IEnumerable` interface. Most of
them are either much like Julia's `Base` functions (or those container here), or not really
needed in Julia. However, there are a couple of useful things I noticed (note that these
operations in LINQ are usually lazy, which may affect what is set of operations is
desirable):

 * Collections can nominate "default values" - I assume these are used for inference-style
   purposes but I'm not sure.
 * `GroupJoin` - a more sensible version of SQL left outer joins. See `leftgroupjoin`.
 * `SelectMany` - like `map` (what they call `Select`) except each mapping is one-to-many
   elements. See `mapmany`.
 * `SequenceEqual` - equality of elements (ignoring keys). This may be different to `==` in
   Julia. Could be `all(map(==, iter1, iter2))` or `mapreduce(==, &, true, iter1, iter2)` in
   Julia (but maybe multi-iterator `all` is better?).
 * `Single` - returns the one and only element of an `IEnumerable`. Throws if there are e.g.
   two elements. See `only`.
 * `TakeWhile` - returns the head of a sequence until some element-predicate is `false`.
 * `ThenBy` - enables lexicographical ordering.

It's also an interesting question whether `map`, `filter`, and so-on should use 
lazy/deferred evaluation in Julia...

## Some related reading (obviously a subset)

 * http://www.andl.org/the-third-manifesto-paraphrase-1/
 * https://github.com/ggaughan/dee (http://www.quicksort.co.uk/DeeDoc.html)
 * https://docs.microsoft.com/en-us/dotnet/csharp/programming-guide/concepts/linq/getting-started-with-linq
 * http://pandas.pydata.org/pandas-docs/stable/
 * https://www.rdocumentation.org/packages/dplyr/versions/0.5.0
