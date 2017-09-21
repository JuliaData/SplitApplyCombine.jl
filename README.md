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

### API

Currently implemented:

 * `group`
 * `groupreduce`
