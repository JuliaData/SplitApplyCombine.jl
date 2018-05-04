@testset "invert" begin
    # arrays of arrays
    a = [[1,2,3],[4,5,6]]
    @test @inferred(invert(a))::Vector{Vector{Int}} == [[1,4],[2,5],[3,6]]
    
    b = [[0,0],[0,0],[0,0]]
    @test invert!(b, a) == [[1,4],[2,5],[3,6]]
end