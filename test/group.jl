@testset "group" begin
    @test group(identity, 1:10) == Dict(Pair.(1:10, (x->[x]).(1:10)))
    @test group(iseven, 1:10) == Dict(true => [2,4,6,8,10], false => [1,3,5,7,9])

    @test group(iseven, x -> x*2, 1:10) == Dict(true => [4,8,12,16,20], false => [2,6,10,14,18])

    @test group((x,y) -> iseven(x+y), (x,y) -> x, 1:10, [1,3,4,2,5,6,4,2,3,9]) == Dict(true => [1,4,5,6,8,9], false => [2,3,7,10])
end
