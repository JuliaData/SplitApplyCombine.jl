@testset "product" begin
    @test @inferred(product(*, [1,2], [1,2,3]))::Matrix{Int} == [1 2 3; 2 4 6]
    @test @inferred(product(*, [1.0,2.0], [1,2,3]))::Matrix{Float64} == [1.0 2.0 3.0; 2.0 4.0 6.0]
    @test isequal(product(*, [1.0,2.0], [1,2,missing]), [1.0 2.0 missing; 2.0 4.0 missing])
    @test isequal(@inferred(product(*, [1.0,2.0], [1,2,missing]))::Matrix{Union{Missing, Float64}}, [1.0 2.0 missing; 2.0 4.0 missing])

    @test @inferred(product(+, fill(1), fill(1)))::Array{Int, 0} == fill(2)
    @test @inferred(product(+, [0,1,2], fill(1)))::Array{Int, 1} == [1,2,3]
    @test @inferred(product(+, fill(1), [0,1,2]))::Array{Int, 1} == [1,2,3]
    @test @inferred(product(+, fill(1), [1 2; 3 4]))::Array{Int, 2} == [2 3; 4 5]
    @test @inferred(product(+, [1 2; 3 4], fill(1)))::Array{Int, 2} == [2 3; 4 5]
    @test size(@inferred(product(+, [1 2 3; 4 5 6], zeros(Int, 4, 5)))::Array{Int, 4}) == (2,3,4,5)
end

@testset "productview" begin
    @test @inferred(productview(*, [1,2], [1,2,3]))::ProductArray{Int,2} == [1 2 3; 2 4 6]
    @test @inferred(productview(*, [1.0,2.0], [1,2,3]))::ProductArray{Float64,2} == [1.0 2.0 3.0; 2.0 4.0 6.0]
    @test isequal(productview(*, [1.0,2.0], [1,2,missing])::ProductArray, [1.0 2.0 missing; 2.0 4.0 missing])
    @test isequal(@inferred(productview(*, [1.0,2.0], [1,2,missing]))::ProductArray{Union{Missing, Float64},2}, [1.0 2.0 missing; 2.0 4.0 missing])

    @test @inferred(productview(+, fill(1), fill(1)))::ProductArray{Int, 0} == fill(2)
    @test @inferred(productview(+, [0,1,2], fill(1)))::ProductArray{Int, 1} == [1,2,3]
    @test @inferred(productview(+, fill(1), [0,1,2]))::ProductArray{Int, 1} == [1,2,3]
    @test @inferred(productview(+, fill(1), [1 2; 3 4]))::ProductArray{Int, 2} == [2 3; 4 5]
    @test @inferred(productview(+, [1 2; 3 4], fill(1)))::ProductArray{Int, 2} == [2 3; 4 5]
    @test size(@inferred(productview(+, [1 2 3; 4 5 6], zeros(Int, 4, 5)))::ProductArray{Int, 4}) == (2,3,4,5)
end

@testset "variadic product" begin
    @test @inferred(product((a, b, c) -> 100a + 10b + c,
                               [1, 2], [3, 4], [5, 6])) ==
          [100a + 10b + c for a in [1, 2], b in [3, 4], c in [5, 6]]
    @test @inferred(product(+, [1, 2], [3.0], [4, 5], [6, 7])) isa Array{Float64, 4}
    @test product(+, [1, 2], [3.0], [4, 5], [6, 7]) ==
          [a + b + c + d for a in [1, 2], b in [3.0], c in [4, 5], d in [6, 7]]
    @test @inferred(product(tuple, [1], ['a'], [true], [2.0], [:x])) ==
          fill((1, 'a', true, 2.0, :x), 1, 1, 1, 1, 1)
    matrix = [1 2 3; 4 5 6]
    @test @inferred(product(+, matrix, [10, 20], fill(100))) ==
          [matrix[i, j] + k + 100 for i in 1:2, j in 1:3, k in [10, 20]]
    @test @inferred(product(+, fill(1), fill(2), fill(3))) == fill(6)
    @test size(@inferred(product(+, Int[], [1, 2], [3]))) == (0, 2, 1)
    @test size(@inferred(product(+, [1, 2], Int[], [3]))) == (2, 0, 1)
    @test size(@inferred(product(+, [1, 2], [3, 4], Int[]))) == (2, 2, 0)
    @test isequal(@inferred(product(+, [1.0, 2.0], [3, missing], [4])),
                  [a + b + c for a in [1.0, 2.0], b in [3, missing], c in [4]])
    @test @inferred(product(+, Float64[], Union{Int, Missing}[], [1])) isa
          Array{Union{Float64, Missing}, 3}
    @test @inferred(product(&, BitVector([true, false]), [false, true], [true])) isa BitArray{3}
    @test product(&, BitVector([true, false]), [false, true], [true]) ==
          [a & b & c for a in [true, false], b in [false, true], c in [true]]
end
