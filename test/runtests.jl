using Vensim2MTK, Test, ModelingToolkit

filepaths=["../examples/Dice.xmile","../examples/lotka.xmile","../examples/commitment2.xmile","../examples/community corona 8.xmile"]
for filepath in filepaths 
    vensim2MTK(filepath, splitext(filepath)[1] * ".jl",true)
end

@testset verbose=true "Dice test output type" begin
    include("../examples/Dice.jl")
    @test isa(sys, ModelingToolkit.ODESystem) 
end

@testset verbose=true "lotka test output type" begin
    include("../examples/lotka.jl")
    @test isa(sys, ModelingToolkit.ODESystem) 
end

@testset verbose=true "commitment2 test output type" begin
    include("../examples/commitment2.jl")
    @test isa(sys, ModelingToolkit.ODESystem) 
end

@testset verbose=true "community corona 8 test output type" begin
    include("../examples/community corona 8.jl")
    @test isa(sys, ModelingToolkit.ODESystem) 
end


