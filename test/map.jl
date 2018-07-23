@testset "mapmany" begin
    @test mapmany(i->1:i, 1:3) == [1, 1,2, 1,2,3]
    @test mapmany((i,j)->1:(i+j), 1:3, 1:3) == [1,2, 1,2,3,4, 1,2,3,4,5,6]
end

@testset "flatten" begin
    @test flatten([1:1, 1:2, 1:3]) == [1, 1,2, 1,2,3]
end

@testset "mapview" begin
    # Arrays
    a = [1,2,3]
    @test @inferred(mapview(-, a)) isa MappedArray{Int,1}
    b = mapview(-, a)
    @test b == [-1,-2,-3]
    a[1] = 11
    @test b == [-11,-2,-3]

    # Iterables
    iter = zip([1,2,3], [1,2,3])
    iter2 = mapview(x -> x[1] + x[2], iter)
    @test @inferred(first(iter2)) === 2
    @test collect(iter2) == [2, 4, 6]
end