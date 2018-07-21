@testset "splitdims" begin
    # Matrix
    @test splitdims([1 2; 3 4]) == [[1,3], [2,4]]
    @test splitdims([1 2; 3 4], 1) == [[1,2], [3,4]]
    @test splitdims([1 2; 3 4], 2) == [[1,3], [2,4]]
    @test splitdims([1 2; 3 4], (1,)) == [[1,2], [3,4]]
    @test splitdims([1 2; 3 4], (2,)) == [[1,3], [2,4]]
    @test splitdims([1 2; 3 4], ()) == fill([1 2; 3 4], ())
    if VERSION < v"0.7-"
        tmp = Matrix{Array{Int, 0}}(2,2) # Stupid hvcat removes the Array{0}'s...
    else
        tmp = Matrix{Array{Int, 0}}(undef,2,2) # Stupid hvcat removes the Array{0}'s...
    end
    tmp[1,1] = fill(1, ()); tmp[1,2] = fill(2, ()); tmp[2,1] = fill(3, ()); tmp[2,2] = fill(4, ())
    @test splitdims([1 2; 3 4], (1, 2)) == tmp
    tmp[1,2][] = 3; tmp[2,1][] = 2
    @test splitdims([1 2; 3 4], (2, 1)) == tmp

    # Vector
    @test splitdims([1,2,3]) == [fill(1, ()), fill(2, ()), fill(3, ())]
    @test splitdims([1,2,3], (1,)) == [fill(1, ()), fill(2, ()), fill(3, ())]
    @test splitdims([1,2,3], ()) == fill([1,2,3], ())

    # Array{0}
    @test splitdims(fill(1, ())) == fill(fill(1, ()), ())
end

@testset "splitdimsview" begin
    # Matrix
    @test splitdimsview([1 2; 3 4]) == [[1,3], [2,4]]
    @test splitdimsview([1 2; 3 4], 1) == [[1,2], [3,4]]
    @test splitdimsview([1 2; 3 4], 2) == [[1,3], [2,4]]
    @test splitdimsview([1 2; 3 4], (1,)) == [[1,2], [3,4]]
    @test splitdimsview([1 2; 3 4], (2,)) == [[1,3], [2,4]]
    @test splitdimsview([1 2; 3 4], ()) == fill([1 2; 3 4], ())
    tmp = Matrix{Array{Int, 0}}(undef,2,2) # Stupid hvcat removes the Array{0}'s...
    tmp[1,1] = fill(1, ()); tmp[1,2] = fill(2, ()); tmp[2,1] = fill(3, ()); tmp[2,2] = fill(4, ())
    @test splitdimsview([1 2; 3 4], (1, 2)) == tmp
    tmp[1,2][] = 3; tmp[2,1][] = 2
    @test splitdimsview([1 2; 3 4], (2, 1)) == tmp

    # Vector
    @test splitdimsview([1,2,3]) == [fill(1, ()), fill(2, ()), fill(3, ())]
    @test splitdimsview([1,2,3], (1,)) == [fill(1, ()), fill(2, ()), fill(3, ())]
    @test splitdimsview([1,2,3], ()) == fill([1,2,3], ())

    # Array{0}
    @test splitdimsview(fill(1, ())) == fill(fill(1, ()), ())
end