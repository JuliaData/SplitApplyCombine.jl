@testset "productview" begin
    splat_times = Inferable(x -> *(x...))
    @test isequal(Generator(splat_times, product([1.0,2.0], [1,2,missing]))::SplitApplyCombine.MappedArray{Union{Missing, Float64},2}, [1.0 2.0 missing; 2.0 4.0 missing])
end
