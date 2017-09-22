# SAC - Split, apply, combine

[![Build Status](https://travis-ci.org/andyferris/SAC.jl.svg?branch=master)](https://travis-ci.org/andyferris/SAC.jl)
[![Coverage Status](https://coveralls.io/repos/andyferris/SAC.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/andyferris/SAC.jl?branch=master)
[![codecov.io](http://codecov.io/github/andyferris/SAC.jl/coverage.svg?branch=master)](http://codecov.io/github/andyferris/SAC.jl?branch=master)

This is my personal playground for exploring data manipulation functions in Julia - their
semantics, design, and functionality. A particular emphasis is placed on ensuring
split-apply-combine strategies are easy to apply, and work relatively optimally for
arbitrary iterables and data structures included in `Base`. 

This package consists of two products: the code, and this document. The code provides an
example implementation of some of the things discussed in this document. This document is
a place to organize thoughts on the data manipulation tools provided in `Base` Julia and
my personal musings.

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

This package is skewed towards the first question; other work focusses more on the second.
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

## API

The package currently implements:

 * `group` (exported)
 * `groupreduce` (exported)
 * `join` (not exported due to clash with `Base`) (also is WIP) 
 * perhaps `joinreduce` makes sense?

## Improving Julia syntax and APIs

Here is some discussion of possible ways to make the data APIs easier to interact with.

### `join`

The `Base.join` function is currently taken by string joins, and strings are iterable. This
presents a rather unfortnate naming clash, since `join` or `Join` is common in a wide
variety of languages to mean these two different operations (which isn't great for Julia's
system of semantically distinct functions). I haven't found an alternative name for either
operation... however I do note that the current `Base.join` on strings is a generalization
of a concatenation operation with seperators added between, which might be a useful
operation for generic iterables.

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
Fortunately, can begin to use keyword arguments and might consider a "simpler" API:

 * `reduce(op, iter; v0 = Default(), final = identity)`
 * `mapreduce(f, op, iter; v0 = Default(), final = identity)`

Here `Default()` would be some built-in to allow us to deal with reductions that start
with or without a `v0`. Taking this to extremes, we may want to put all the functions in
as keyword arguments (the default values are not thought out, rather chosen at random):

 * `map(iters...; f = identity)`
 * `reduce(iter; op = tuple, v0 = Default(), final = identity)`
 * `mapreduce(iters...; f = identity, op = tuple, v0 = Default(), final = identity)`
 * `group(iters...; by = identity, f = identity)`
 * `groupreduce(iters...; by = identity, f = identity, op = tuple, v0 = Default(), final = identity)`
 * `join` - TODO

(probably the default value of `op` should throw an error upon call, reminding the user to
explicitly specify `op`). Note that the above standardize where the containers sit, as
positional arguments, and share the same keyword names where they overlap. One could
imagine removing `mapreduce` and instead putting an `f` keyword argument into `reduce` with
default as `identity`.

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
