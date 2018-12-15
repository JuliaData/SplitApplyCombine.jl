@testset "innerjoin" begin
    @testset "UnitRange" begin
	    l = 2:5
	    r = 3:6
        @test collect(Iterators.filter(Match(), product(l, r))) == [(3,3), (4,4), (5,5)]
	    @test collect(Iterators.filter(Match(compare = isless), product(l, r))) ==
            [(2,3), (2,4), (2,5), (2,6), (3,4), (3,5), (3,6), (4,5), (4,6), (5,6)]
	end

	@testset "Arrays of NamedTuple" begin
	    l = [(a=1, b=2.0), (a=2, b=4.0), (a=3, b=6.0)]
	    r = [(a=1, c=:a), (a=2, c=:b), (a=4,c=:d)]
<<<<<<< HEAD
	    @test collect(Generator(t -> merge(t...), Iterators.filter(Match(key = Names(:a)), product(l, r)))) ==
=======
	    @test collect(Generator(t -> merge(t...), Iterators.filter(Match(key = x -> x.a), product(l, r)))) ==
>>>>>>> restore previous code
            [(a=1, b=2.0, c=:a), (a=2, b=4.0, c=:b)]
	end
end
