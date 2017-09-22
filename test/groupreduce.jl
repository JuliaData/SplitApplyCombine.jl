@testset "groupreduce" begin
    @test groupreduce(identity, +, 1:10) == Dict(Pair.(1:10, 1:10))
    @test groupreduce(iseven, +, 1:10) == Dict(true => 30, false => 25)
 
    @test groupreduce(iseven, x -> x*2, +, 1:10) == Dict(true => 60, false => 50)

    @test groupreduce(iseven, x -> x*2, +, 10, 1:10) == Dict(true => 70, false => 60)

    @test groupreduce((x,y) -> iseven(x+y), (x,y) -> x+y, +, 10, 1:10, 1:10) == Dict(true => 120)
    @test groupreduce((x,y) -> iseven(x+y), (x,y) -> x+y, +, 10, 1:10, [1,3,4,2,5,6,4,2,3,9]) == Dict(true => 62, false => 52)
end
