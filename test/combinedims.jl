@testset "combinedims" begin
    m = [1 2 3 4; 5 6 7 8; 9 10 11 12]
    vv = [[1,2,3,4],[5,6,7,8],[9,10,11,12]]
    @test combinedims(vv) == m

    @test combinedimsview(vv) == m
end