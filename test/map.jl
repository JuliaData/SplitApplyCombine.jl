@testset "mapmany" begin
    @test @inferred(mapmany(i->1:i, 1:3))::Vector{Int} == [1, 1,2, 1,2,3]
    @test @inferred(mapmany((i,j)->1:(i+j), 1:3, 1:3))::Vector{Int} == [1,2, 1,2,3,4, 1,2,3,4,5,6]

    a = @inferred(mapmany(i -> StructVector(a=1:i), [2, 3]))::StructArray
    @test a == [(a=1,), (a=2,), (a=1,), (a=2,), (a=3,)]
    @test a.a == [1, 2, 1, 2, 3]

    cnt = Ref(0)
    @test mapmany(i -> [cnt[] += 1], 1:3)::Vector{Int} == [1, 2, 3]
    @test cnt[] == 3

    @test @inferred(mapmany(i -> (j for j in 1:i), (i for i in 1:3))) == [1, 1,2, 1,2,3]
    @test @inferred(mapmany(i -> 1:i, [1 3; 2 4]))::Vector{Int} == [1, 1,2, 1,2,3, 1,2,3,4]
    @test @inferred(mapmany(i -> reshape(1:i, 2, :), [2, 4]))::Vector{Int} == [1, 2, 1, 2, 3, 4]
end

@testset "flatten" begin
    @test @inferred(flatten([1:1, 1:2, 1:3])) == [1, 1,2, 1,2,3]

    a = @inferred(flatten([StructVector(a=[1, 2]), StructVector(a=[1, 2, 3])]))::StructArray
    @test a == [(a=1,), (a=2,), (a=1,), (a=2,), (a=3,)]
    @test a.a == [1, 2, 1, 2, 3]
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

@testset "filterview" begin
    a = [1, 2, 3]
    @test @inferred(filterview(x -> x >= 2, a)) == [2, 3]
    filterview(x -> x >= 2, a)[1] = 10
    @test a == [1, 10, 3]
end
