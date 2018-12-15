@testset "leftgroupjoin" begin
    l = [1,2,3,4]
    r = [0,1,2]
    ans1 = Dict(1 => [(1,1)],
                2 => [(2,2)],
                3 => [],
                4 => [])
    ans2 = Dict(false => [(1, 1), (3, 1)],
                true => [(2, 0), (2, 2), (4, 0), (4, 2)])


    @test leftgroupjoin(Match(), l ,r) == ans1
    @test leftgroupjoin(Match(key = iseven), l,  r) == ans2
    @test leftgroupjoin(Match(key = iseven, compare = (==)), l, r) == ans2
end
