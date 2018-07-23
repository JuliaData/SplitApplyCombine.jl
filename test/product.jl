@testset "product" begin
    @test @inferred(product(*, [1,2], [1,2,3]))::Matrix{Int} == [1 2 3; 2 4 6]
    @test @inferred(product(*, [1.0,2.0], [1,2,3]))::Matrix{Float64} == [1.0 2.0 3.0; 2.0 4.0 6.0]
    @test isequal(product(*, [1.0,2.0], [1,2,missing]), [1.0 2.0 missing; 2.0 4.0 missing])
    @test_broken isequal(@inferred(product(*, [1.0,2.0], [1,2,missing]))::Matrix{Union{Missing, Float64}}, [1.0 2.0 missing; 2.0 4.0 missing])

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
    @test isequal(productview(*, [1.0,2.0], [1,2,missing]), [1.0 2.0 missing; 2.0 4.0 missing])
    @test_broken isequal(@inferred(productview(*, [1.0,2.0], [1,2,missing]))::ProductArray{Union{Missing, Float64},2}, [1.0 2.0 missing; 2.0 4.0 missing])

    @test @inferred(productview(+, fill(1), fill(1)))::ProductArray{Int, 0} == fill(2)
    @test @inferred(productview(+, [0,1,2], fill(1)))::ProductArray{Int, 1} == [1,2,3]
    @test @inferred(productview(+, fill(1), [0,1,2]))::ProductArray{Int, 1} == [1,2,3]
    @test @inferred(productview(+, fill(1), [1 2; 3 4]))::ProductArray{Int, 2} == [2 3; 4 5]
    @test @inferred(productview(+, [1 2; 3 4], fill(1)))::ProductArray{Int, 2} == [2 3; 4 5]
    @test size(@inferred(productview(+, [1 2 3; 4 5 6], zeros(Int, 4, 5)))::ProductArray{Int, 4}) == (2,3,4,5)
end