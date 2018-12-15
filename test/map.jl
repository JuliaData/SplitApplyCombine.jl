@testset "mapview" begin
    # Arrays
    a = [1,2,3]
    @test @inferred(Generator(Inferable(-), a)) isa SplitApplyCombine.MappedArray{Int,1}
    b = Generator(Inferable(-), a)
    @test b == [-1,-2,-3]
    a[1] = 11
    @test b == [-11,-2,-3]
end
