@testset "innerjoin" begin
    @testset "UnitRange" begin
	    l = 2:5
	    r = 3:6
	    @test innerjoin(identity, identity, tuple, l, r) == [(3,3), (4,4), (5,5)]
	    @test innerjoin(identity, identity, tuple, isequal, l, r) == [(3,3), (4,4), (5,5)]
	    @test innerjoin(identity, identity, tuple, ==, l, r) == [(3,3), (4,4), (5,5)]

	    @test innerjoin(identity, identity, tuple, isless, l, r) == [(2,3), (2,4), (2,5), (2,6), (3,4), (3,5), (3,6), (4,5), (4,6), (5,6)]
	end

	@testset "Arrays of NamedTuple" begin
	    l = [(a=1, b=2.0), (a=2, b=4.0), (a=3, b=6.0)]
	    r = [(a=1, c=:a), (a=2, c=:b), (a=4,c=:d)]
	    @test innerjoin(x->x.a, x->x.a, l, r) == [(a=1, b=2.0, c=:a), (a=2, b=4.0, c=:b)]
	end
end