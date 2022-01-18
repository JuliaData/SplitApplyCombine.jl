@testset "combinedims" begin
    m = [1 5 9; 2 6 10; 3 7 11; 4 8 12]
    vv = [[1,2,3,4],[5,6,7,8],[9,10,11,12]]

    @testset for combine in (combinedims, combinedimsview)
        @test @inferred(size(combine(vv))) == size(m)
        @test @inferred(axes(combine(vv))) == axes(m)
        @test @inferred(combine(vv)) == m
        @test @inferred(combine(vv)[2, 1]) == m[2, 1]
    
        @test @inferred(size(combine(vv, 2))) == size(m)
        @test @inferred(axes(combine(vv, 2))) == axes(m)
        @test @inferred(combine(vv, 2)) == m
        @test @inferred(combine(vv, 2)[2, 1]) == m[2, 1]
        @test @inferred(combine(vv, 1)) == permutedims(m)

        A = rand(2, 3, 5, 7)
        @test @inferred(combine(splitdims(A))) == A
        @testset for d in [1:ndims(A); (1, 2); (1, 3); (2, 3); (2, 4); (1, 2, 3); (1, 2, 4); (2, 3, 4); (1, 2, 3, 4)]
            @test @inferred(combine(splitdims(A, d), d)) == A
            @test @inferred(combine(splitdims(A, d), d)[1, 2, 3, 4]) == A[1, 2, 3, 4]
        end
    end

    c_copy = combinedims(vv)
    c_view = combinedimsview(vv)
    vv[1][3] = 100
    @test c_copy[3, 1] == 3
    @test c_view[3, 1] == 100

    stat = [SVector(1, 2), SVector(3, 4), SVector(5, 6)]
    @test @inferred(combinedims(stat)) == [1 3 5; 2 4 6]
    # infer to a union:
    @test combinedims(stat, 1) == [1 2; 3 4; 5 6]
    @test combinedims(stat, 2) == [1 3 5; 2 4 6]
    @testset for ds in [(), (1,), (2,)]
        cv = @inferred(combinedimsview(stat, ds...))
        @inferred(size(cv))
        @inferred(cv[1, 2])
    end
end
