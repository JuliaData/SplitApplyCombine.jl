
@testset "underscore" begin
    data = [1,2,3]
    @test @_(data |> sum(_)) == 6
    a = 10
    @test @_(data |> _ .+ a) == data .+ a
    @test @_(data |> _.^2 .+ _ |> sum) == sum(data.^2 .+ data)

    two_outputs(x) = (x, x.+1)
    @test @_(data |> two_outputs |> _[1] |> sum) == sum(data)
    @test @_(data |> two_outputs |> _[2] |> sum) == sum(data.+1)
end

