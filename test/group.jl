@testset "group" begin
    result = group(iseven, 1:10)
    @test collect(collect(result)[false]) == [1, 3, 5, 7, 9]
    @test map(Reduce(+), result) == Dict(false => 25, true => 30)
    @test map(count, result) == Dict(false => 5, true => 5)
end
