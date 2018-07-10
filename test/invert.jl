@testset "invert" begin
    # arrays of arrays
    a = [[1,2,3],[4,5,6]]
    @test @inferred(invert(a))::Vector{Vector{Int}} == [[1,4],[2,5],[3,6]]
    
    b = [[0,0],[0,0],[0,0]]
    @test invert!(b, a) == [[1,4],[2,5],[3,6]]

    # tuples of tuples
    tt = ((true, 2.0, 3f0), ('d', 0x05, 6))
    @test @inferred(invert(tt)) === ((true, 'd'), (2.0, 0x05), (3f0, 6))

    # tuples / arrays
    #ta = ([1, 2], [3.1, 4.1])
    #at = [(1, 3.1), (2, 4.1)]
    #@test @inferred(invert(ta))::Vector{Tuple{Int, Float64}} == at
    #@test @inferred(invert(at))::Tuple{Vector{Int}, Vector{Float64}} == ta
end