@testset "join" begin
    l = 2:5
    r = 3:6
    @test SAC.join(l, r) == [(3,3), (4,4), (5,5)]
    @test SAC.join(identity, identity, l, r) == [(3,3), (4,4), (5,5)]
    @test SAC.join(identity, identity, tuple, l, r) == [(3,3), (4,4), (5,5)]
    @test SAC.join(identity, identity, tuple, isequal, l, r) == [(3,3), (4,4), (5,5)]
    @test SAC.join(identity, identity, tuple, ==, l, r) == [(3,3), (4,4), (5,5)]

    @test SAC.join(identity, identity, tuple, isless, l, r) == [(2,3), (2,4), (2,5), (2,6), (3,4), (3,5), (3,6), (4,5), (4,6), (5,6)]
end