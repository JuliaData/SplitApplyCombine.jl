@testset "invert" begin
    # arrays of arrays
    a = [[1,2,3],[4,5,6]]
    @test @inferred(invert(a))::Vector{Vector{Int}} == [[1,4],[2,5],[3,6]]
    
    b = [[0,0],[0,0],[0,0]]
    @test invert!(b, a) == [[1,4],[2,5],[3,6]]

    # Issue #14
    a3 = [[1 2; 3 4],[5 6; 7 8]]
    result3 = Matrix{Vector{Int}}(undef,2,2) # literal syntax is `hvcat`... :(
    result3[1, 1] = [1, 5]
    result3[1, 2] = [2, 6]
    result3[2, 1] = [3, 7]
    result3[2, 2] = [4, 8]
    @test @inferred(invert(a3))::Matrix{Vector{Int}} == result3

    # tuples of tuples
    tt = ((true, 2.0, 3f0), ('d', 0x05, 6))
    @test @inferred(invert(tt)) === ((true, 'd'), (2.0, 0x05), (3f0, 6))

    # tuples / arrays
    ta = ([1, 2], [3.1, 4.1])
    at = [(1, 3.1), (2, 4.1)]
    @test @inferred(invert(ta))::Vector{Tuple{Int, Float64}} == at
    @test @inferred(invert(at))::Tuple{Vector{Int}, Vector{Float64}} == ta

    # named tuples
    nn = (a = (x = true, y = 2), b = (x = 3.0, y = 4.0f0))
    @test @inferred(invert(nn)) === (x = (a = true, b = 3.0), y = (a = 2, b = 4.0f0))

    # tuples / named tuples
    tn = ((a = true, b = 2), (a = 3.0, b = 4.0f0))
    nt = (a = (true, 3.0), b = (2, 4.0f0))
    @test @inferred(invert(nt)) === tn
    @test @inferred(invert(tn)) === nt

    # arrays / named tuples
    na = (a = [1,2,3], b = [2.0, 4.0, 6.0])
    an = [(a = 1, b = 2.0), (a = 2, b = 4.0), (a = 3, b = 6.0)]
    @test @inferred(invert(na))::typeof(an) == an
    @test @inferred(invert(an))::typeof(na) == na
end
