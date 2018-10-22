@testset "leftgroupjoin" begin
    l = [1,2,3,4]
    r = [0,1,2]
    ans1 = Dict(1 => [(1,1)],
                2 => [(2,2)],
                3 => [],
                4 => []) 
    ans2 = Dict(false => [(1, 1), (3, 1)],
                true => [(2, 0), (2, 2), (4, 0), (4, 2)])


    @test leftgroupjoin(identity, identity, tuple, l ,r) == ans1
    @test leftgroupjoin(iseven, iseven, tuple, l,  r) == ans2
    @test leftgroupjoin(iseven, iseven, tuple, ==, l, r) == ans2
end