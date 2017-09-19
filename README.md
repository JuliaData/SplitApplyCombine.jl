# SAC - Split, apply, combine

[![Build Status](https://travis-ci.org/andyferris/SAC.jl.svg?branch=master)](https://travis-ci.org/andyferris/SAC.jl)

[![Coverage Status](https://coveralls.io/repos/andyferris/SAC.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/andyferris/SAC.jl?branch=master)

[![codecov.io](http://codecov.io/github/andyferris/SAC.jl/coverage.svg?branch=master)](http://codecov.io/github/andyferris/SAC.jl?branch=master)

A playground for exploring generic (and concrete) split-apply-combine strategies in Julia,
and related data manipulation operations.

Part of the goal is to determine APIs that work well for both base Julia arrays and dicts,
and also extend to tables or dataframes in a natural way.

### API

Currently implemented

 * `groupby`