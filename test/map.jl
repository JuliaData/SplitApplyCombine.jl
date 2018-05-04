@testset "mapmany" begin
    @test mapmany(i->1:i, 1:3) == [1, 1,2, 1,2,3]
    @test mapmany((i,j)->1:(i+j), 1:3, 1:3) == [1,2, 1,2,3,4, 1,2,3,4,5,6]
end

@testset "flatten" begin
    @test flatten([1:1, 1:2, 1:3]) == [1, 1,2, 1,2,3]
end