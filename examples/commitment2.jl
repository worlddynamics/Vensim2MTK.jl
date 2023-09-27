using IfElse
using SpecialFunctions
using ModelingToolkit
using DifferentialEquations
using DataInterpolations

@variables t
D = Differential(t)
@parameters TIME_STEP=1 [description = "TIME_STEP, the dt of the model"]
     @variables t_plus(t) = TIME_STEP/2 [description= "t_plus, variable used for pulse to avoid rounding errors"]
@parameters r_Conversion = 1.0 [description = "r_Conversion"]
@parameters u_Nonsocial_deradicalization = 0.0 [description = "u_Nonsocial_deradicalization"]
@parameters r_Moderate_evangelism = 0.0 [description = "r_Moderate_evangelism"]
@parameters s_Stubbornness = 0.0 [description = "s_Stubbornness"]
@parameters p_fraction_of_Ac_zealots = 0.137 [description = "p_fraction_of_Ac_zealots"]
@parameters r_Moderation = 1.0 [description = "r_Moderation"]
@variables nA_fraction_holding_A_view(t) = 0 [description = "nA_fraction_holding_A_view"]
@variables nAB_fraction_moderate(t) = 0 [description = "nAB_fraction_moderate"]
@variables nB_fraction_holding_B_view(t) = (1) - (0.137) [description = "nB_fraction_holding_B_view"]
@variables Conversion_to_A(t)  [description = "Conversion_to_A"]
@variables Conversion_to_B(t)  [description = "Conversion_to_B"]
@variables Moderation_of_A(t)  [description = "Moderation_of_A"]
@variables Moderation_of_B(t)  [description = "Moderation_of_B"]

    eqs = [
        t_plus ~ t + (TIME_STEP / 2)
    	D(nA_fraction_holding_A_view) ~ Conversion_to_A - Moderation_of_A
	D(nAB_fraction_moderate) ~ Moderation_of_A + Moderation_of_B - Conversion_to_A - Conversion_to_B
	D(nB_fraction_holding_B_view) ~ Conversion_to_B - Moderation_of_B
	Conversion_to_A ~ ((p_fraction_of_Ac_zealots) + (nA_fraction_holding_A_view)) * ((nAB_fraction_moderate) * (((1) - (s_Stubbornness)) * (r_Conversion)))
	Conversion_to_B ~ (nB_fraction_holding_B_view) * ((nAB_fraction_moderate) * (((1) - (s_Stubbornness)) * (r_Conversion)))
	Moderation_of_A ~ ((nA_fraction_holding_A_view) * ((nB_fraction_holding_B_view) * (r_Moderation))) + (((r_Moderate_evangelism) * ((nA_fraction_holding_A_view) * (nAB_fraction_moderate))) + ((u_Nonsocial_deradicalization) * (nA_fraction_holding_A_view)))
	Moderation_of_B ~ (((p_fraction_of_Ac_zealots) + (nA_fraction_holding_A_view)) * ((nB_fraction_holding_B_view) * (r_Moderation))) + (((r_Moderate_evangelism) * ((nB_fraction_holding_B_view) * (nAB_fraction_moderate))) + ((u_Nonsocial_deradicalization) * (nB_fraction_holding_B_view)))
]
     
     
 @named sys= ODESystem(eqs)
 sys= structural_simplify(sys)
 prob= ODEProblem(sys,[],(0,100), solver=RK4, dt=1, dtmax=1)
                     solved=solve(prob)
                         