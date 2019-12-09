@testset "only" begin
    @test only([3]) === 3
    @test_throws Exception only([])
    @test_throws Exception only([3, 2])

    @test only((3,)) === 3
    @test_throws Exception only(())
    @test_throws Exception only((3, 2))

    @test only(Dict(1=>3)) === (1=>3)
    @test_throws Exception only(Dict{Int,Int}())
    @test_throws Exception only(Dict(1=>3, 2=>2))
end