@testset "group" begin
    @test group(identity, 11:20) == Dict(Pair.(11:20, (x->[x]).(11:20)))
    @test group(iseven, 1:10) == Dict(true => [2,4,6,8,10], false => [1,3,5,7,9])

    @test group(iseven, x -> x*2, 1:10) == Dict(true => [4,8,12,16,20], false => [2,6,10,14,18])

    @test group((x,y) -> iseven(x+y), (x,y) -> x, 1:10, [1,3,4,2,5,6,4,2,3,9]) == Dict(true => [1,4,5,6,8,9], false => [2,3,7,10])
end

@testset "groupinds" begin
    @test groupinds(identity, 11:20) == Dict(Pair.(11:20, (x->[x]).(1:10)))
    @test groupinds(iseven, 11:20) == Dict(true => [2,4,6,8,10], false => [1,3,5,7,9])
end

@testset "groupview" begin
    @test groupview(identity, 11:20)::Groups == group(identity, 11:20)::Dict
    @test groupview(iseven, 11:20)::Groups == group(iseven, 11:20)::Dict
end

@testset "groupreduce" begin
    @test groupreduce(identity, +, 1:10) == Dict(Pair.(1:10, 1:10))
    @test groupreduce(iseven, +, 1:10) == Dict(true => 30, false => 25)

    @test groupreduce(iseven, +, x -> x*2, 1:10) == Dict(true => 60, false => 50)

    @test groupreduce(iseven, +, x -> x*2, 1:10; init=10) == Dict(true => 70, false => 60)

    @test groupreduce((x,y) -> iseven(x+y), +, (x,y) -> x+y, 1:10, 1:10; init=10) == Dict(true => 120)
    @test groupreduce((x,y) -> iseven(x+y), +, (x,y) -> x+y, 1:10, [1,3,4,2,5,6,4,2,3,9]; init=10) == Dict(true => 62, false => 52)

    @test grouplength(iseven, 1:10) == Dict(true => 5, false => 5)
    @test groupsum(iseven, 1:10) == Dict(true => 30, false => 25)
    @test groupprod(iseven, 1:10) == Dict(true => 2*4*6*8*10, false => 1*3*5*7*9)
end