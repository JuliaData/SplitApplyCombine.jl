@testset "splitdims" begin
    # Matrix
    @test splitdims([1 2; 3 4]) == [[1,3], [2,4]]
    @test splitdims([1 2; 3 4], 1) == [[1,2], [3,4]]
    @test splitdims([1 2; 3 4], 2) == [[1,3], [2,4]]
    @test splitdims([1 2; 3 4], ()) == fill([1 2; 3 4], ())
    @test splitdims([1 2; 3 4], (1,)) == [[1,2], [3,4]]
    @test splitdims([1 2; 3 4], (2,)) == [[1,3], [2,4]]
    @test splitdims([1 2; 3 4], (1, 2)) == [fill(1, ()) fill(2, ()); fill(3, ()) fill(4, ())]
    @test splitdims([1 2; 3 4], (2, 1)) == [fill(1, ()) fill(3, ()); fill(2, ()) fill(4, ())]

    # Vector
    @test_broken splitdims([1,2,3]) == [fill(1, ()), fill(2, ()), fill(3, ())]
    @test_broken splitdims([1,2,3], (1,)) == [fill(1, ()), fill(2, ()), fill(3, ())]
    @test splitdims([1,2,3], ()) == fill([1,2,3], ())

    # Array{0}
    @test splitdims(fill(1, ())) == fill(fill(1, ()), ())
end