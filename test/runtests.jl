using Vensim2MTK, Test, ModelingToolkit

filepaths=["..\\examples\\Dice.xmile","..\\examples\\Lokta.xmile","..\\examples\\commitment2.xmile","..\\examples\\community corona 8.xmile"]
for filepath in filepaths 
    vensim2MTK(filepath, splitext(basename(filepath))[1] * ".jl",true)
end
@testset verboe=true "Vensim2MTK.jl" begin
    @test isa(Dice.solved, ModelingToolkit.ODESystem)
    @test isa(Lokta.solved, ModelingToolkit.ODESystem)
    @test isa(commitment.solved, ModelingToolkit.ODESystem)
    @test isa(community_corona_8.solved, ModelingToolkit.ODESystem)
end

