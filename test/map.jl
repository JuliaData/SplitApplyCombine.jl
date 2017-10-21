@testset "mapmany" begin
    @test mapmany(i->1:i, 1:3) == [1, 1,2, 1,2,3]
end

@testset "flatten" begin
    @test flatten([1:1, 1:2, 1:3]) == [1, 1,2, 1,2,3]
end