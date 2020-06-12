@testset "group" begin
    @test group(identity, 11:20)::Dictionary == Dictionary(11:20, (x->[x]).(11:20))
    @test group(iseven, 1:10)::Dictionary == dictionary([false => [1,3,5,7,9], true => [2,4,6,8,10]])

    @test group(iseven, x -> x*2, 1:10)::Dictionary == dictionary([false => [2,6,10,14,18], true => [4,8,12,16,20]])

    @test group((x,y) -> iseven(x+y), (x,y) -> x, 1:10, [1,3,4,2,5,6,4,2,3,9])::Dictionary == dictionary([true => [1,4,5,6,8,9], false => [2,3,7,10]])
end

@testset "grouponly" begin
    @test grouponly(identity, 11:20)::Dictionary == Dictionary(11:20, 11:20)
    @test_throws IndexError grouponly(iseven, 11:20)
end

@testset "groupunique" begin
    @test groupunique(identity, 11:20)::Dictionary{Int, Indices{Int}} == Dictionary(11:20, map(x -> Indices([x]), 11:20))
    @test groupunique(iseven, 11:20)::Dictionary{Bool, Indices{Int}} == dictionary([false => Indices([11,13,15,17,19]), true => Indices([12,14,16,18,20])])
end

@testset "groupfind" begin
    @test groupfind(identity, 11:20) == Dictionary(11:20, (x->[x]).(1:10))
    @test groupfind(iseven, 11:20) == dictionary([false => [1,3,5,7,9], true => [2,4,6,8,10]])
end

@testset "groupview" begin
    @test groupview(identity, 11:20)::GroupDictionary == group(identity, 11:20)::Dictionary
    @test groupview(iseven, 11:20)::GroupDictionary == group(iseven, 11:20)::Dictionary
end

@testset "groupreduce" begin
    @test groupreduce(identity, +, 1:10) == Dictionary(1:10, 1:10)
    @test groupreduce(iseven, +, 1:10) == dictionary([false => 25, true => 30])

    @test groupreduce(iseven, x -> x*2, +, 1:10) == dictionary([false => 50, true => 60])

    @test groupreduce(iseven, x -> x*2, +, 1:10; init=10) == dictionary([false => 60, true => 70])

    @test groupreduce((x,y) -> iseven(x+y), (x,y) -> x+y, +, 1:10, 1:10; init=10) == dictionary([true => 120])
    @test groupreduce((x,y) -> iseven(x+y), (x,y) -> x+y, +, 1:10, [1,3,4,2,5,6,4,2,3,9]; init=10) == dictionary([true => 62, false => 52])

    @test groupcount(iseven, 1:10) == dictionary([false => 5, true => 5])
    @test groupsum(iseven, 1:10) == dictionary([false => 25, true => 30])
    @test groupprod(iseven, 1:10) == dictionary([false => 1*3*5*7*9, true => 2*4*6*8*10])
    @test groupfirst(iseven, 1:10) == dictionary([false => 1, true => 2])
    @test grouplast(iseven, 1:10) == dictionary([false => 9, true => 10])
end
