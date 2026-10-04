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

    @testset "Indexed iterables" begin
        parent = (1, 2, 3)
        mapped = mapview(x -> 10x, parent)
        @test collect(mapped) == [10, 20, 30]
        @test @inferred(mapped[2]) == 20
        @test [mapped[i] for i in keys(mapped)] == collect(mapped)
        @test @inferred(mapview(string, parent)[3]) == "3"
        @test @inferred(mapview(abs, (a=-1, b=-2))[:b]) == 2
        @test_throws BoundsError mapped[4]
        @test_throws DomainError mapview(x -> throw(DomainError(x)), parent)[1]
        calls = Ref(0)
        lazy = mapview(parent) do x
            calls[] += 1
            x + 1
        end
        @test calls[] == 0
        @test lazy[2] == 3
        @test calls[] == 1
    end
end

@testset "filterview" begin
    a = [1, 2, 3]
    @test @inferred(filterview(x -> x >= 2, a)) == [2, 3]
    filterview(x -> x >= 2, a)[1] = 10
    @test a == [1, 10, 3]
end
