using Random
using SplitApplyCombine
using BenchmarkTools

# 1
srand(42)
a = rand(1:100, 10_000)
b = rand(1:100, 10_000)

b1 = @benchmark leftgroupjoin($identity, $identity, $((x,y) -> x), $isequal, $a, $b)
b2 = @benchmark SplitApplyCombine.leftgroupjoin2($identity, $identity, $((x,y) -> x), $isequal, $a, $b)
