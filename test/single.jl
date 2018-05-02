@testset "single" begin
    @test single([3]) === 3
    @test_throws Exception single([])
    @test_throws Exception single([3, 2])

    @test single((3,)) === 3
    @test_throws Exception single(())
    @test_throws Exception single((3, 2))

    @test single(Dict(1=>3)) === (1=>3)
    @test_throws Exception single(Dict{Int,Int}())
    @test_throws Exception single(Dict(1=>3, 2=>2))

    #@test single(Nullable(1)) === 1
    #@test_throws Exception Only(Nullable{Int}())
end