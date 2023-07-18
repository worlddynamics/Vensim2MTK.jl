using IfElse
using SpecialFunctions
using ModelingToolkit
using DifferentialEquations
using Plots 

#variables and parameters of the model (the variable/parameter name "t" is forbiden)
@variables t
D = Differential(t)
@parameters TIME_STEP=0.125 [description = "TIME_STEP, the dt of the model"]
@variables t_plus = TIME_STEP/2 [description= "t_plus, variable used for pulse to avoid rounding errors"]
@parameters Fraction_Requiring_Hospitalization = 0.1 [description = "Fraction_Requiring_Hospitalization"]
@parameters Untreated_Fatality_Rate = 0.04 [description = "Untreated_Fatality_Rate"]
@parameters Contact_Density_Decline = 0.0 [description = "Contact_Density_Decline"]
@parameters Isolation_Reaction_Time = 2.0 [description = "Isolation_Reaction_Time"]
@parameters Infection_Duration = 7.0 [description = "Infection_Duration"]
@parameters Initial_Population = 100000.0 [description = "Initial_Population"]
@parameters Public_Health_Capacity_Sensitivity = 2.0 [description = "Public_Health_Capacity_Sensitivity"]
@parameters R0 = 3.3 [description = "R0"]
@parameters Seasonal_Period = 365.0 [description = "Seasonal_Period"]
@parameters Hospital_Capacity = 100.0 [description = "Hospital_Capacity"]
@parameters Behavior_Reaction_Time = 20.0 [description = "Behavior_Reaction_Time"]
@parameters Hospital_Capacity_Sensitivity = 2.0 [description = "Hospital_Capacity_Sensitivity"]
@parameters Potential_Isolation_Effectiveness = 0.0 [description = "Potential_Isolation_Effectiveness"]
@parameters Behavioral_Risk_Reduction = 0.0 [description = "Behavioral_Risk_Reduction"]
@parameters Peak_Season = 0.0 [description = "Peak_Season"]
@parameters Public_Health_Capacity = 1000.0 [description = "Public_Health_Capacity"]
@parameters Treated_Fatality_Rate = 0.01 [description = "Treated_Fatality_Rate"]
@parameters Seasonal_Amplitude = 0.0 [description = "Seasonal_Amplitude"]
@parameters N_Imported_Infections = 3.0 [description = "N_Imported_Infections"]
@parameters Import_Time = 10.0 [description = "Import_Time"]
@parameters Incubation_Time = 5.0 [description = "Incubation_Time"]
@variables Infected(t) = 0 [description = "Infected"]
@variables Susceptible(t) = 100000.0 [description = "Susceptible"]
@variables Exposed(t) = 0 [description = "Exposed"]
@variables Deaths(t) = 0 [description = "Deaths"]
@variables Recovered(t) = 0 [description = "Recovered"]
@variables Active_Infected(t)  [description = "Active_Infected"]
@variables Advancing(t)  [description = "Advancing"]
@variables Dying(t)  [description = "Dying"]
@variables Effect_of_Season(t)  [description = "Effect_of_Season"]
@variables Fatality_Rate(t)  [description = "Fatality_Rate"]
@variables Fraction_Susceptible(t)  [description = "Fraction_Susceptible"]
@variables Hospital_Strain(t)  [description = "Hospital_Strain"]
@variables Importing_Infected(t)  [description = "Importing_Infected"]
@variables Infecting(t)  [description = "Infecting"]
@variables Initial_Uncontrolled_Transmission_Rate(t)  [description = "Initial_Uncontrolled_Transmission_Rate"]
@variables TEMPVAR1_Isolation_Effectiveness(t) = 42 [description = "TEMPVAR1_Isolation_Effectiveness, created by the \"SMOOTH\" function or an afiliate. Value is false the first execution, find the real initial value after the first execution"]
@variables TEMPVAR2_Isolation_Effectiveness(t) = 42 [description = "TEMPVAR2_Isolation_Effectiveness, created by the \"SMOOTH\" function or an afiliate. Value is false the first execution, find the real initial value after the first execution"]
@variables TEMPVAR3_Isolation_Effectiveness(t) = 42 [description = "TEMPVAR3_Isolation_Effectiveness, created by the \"SMOOTH\" function or an afiliate. Value is false the first execution, find the real initial value after the first execution"]
@variables TEMPVARSMOOTHED1_Isolation_Effectiveness(t) = TEMPVAR1_Isolation_Effectiveness [description = "TEMPVARSMOOTHED1_Isolation_Effectiveness, created by the \"SMOOTH\" function or an afiliate"]
@variables TEMPVARSMOOTHED2_Isolation_Effectiveness(t) = TEMPVAR2_Isolation_Effectiveness [description = "TEMPVARSMOOTHED2_Isolation_Effectiveness, created by the \"SMOOTH\" function or an afiliate"]
@variables TEMPVARSMOOTHED3_Isolation_Effectiveness(t) = TEMPVAR3_Isolation_Effectiveness [description = "TEMPVARSMOOTHED3_Isolation_Effectiveness, created by the \"SMOOTH\" function or an afiliate"]
@variables Isolation_Effectiveness(t)  [description = "Isolation_Effectiveness"]
@variables Public_Health_Strain(t)  [description = "Public_Health_Strain"]
@variables Recovering(t)  [description = "Recovering"]
@variables TEMPVAR1_Relative_Behavioral_Risk(t) = 42 [description = "TEMPVAR1_Relative_Behavioral_Risk, created by the \"SMOOTH\" function or an afiliate. Value is false the first execution, find the real initial value after the first execution"]
@variables TEMPVAR2_Relative_Behavioral_Risk(t) = 42 [description = "TEMPVAR2_Relative_Behavioral_Risk, created by the \"SMOOTH\" function or an afiliate. Value is false the first execution, find the real initial value after the first execution"]
@variables TEMPVAR3_Relative_Behavioral_Risk(t) = 42 [description = "TEMPVAR3_Relative_Behavioral_Risk, created by the \"SMOOTH\" function or an afiliate. Value is false the first execution, find the real initial value after the first execution"]
@variables TEMPVARSMOOTHED1_Relative_Behavioral_Risk(t) = TEMPVAR1_Relative_Behavioral_Risk [description = "TEMPVARSMOOTHED1_Relative_Behavioral_Risk, created by the \"SMOOTH\" function or an afiliate"]
@variables TEMPVARSMOOTHED2_Relative_Behavioral_Risk(t) = TEMPVAR2_Relative_Behavioral_Risk [description = "TEMPVARSMOOTHED2_Relative_Behavioral_Risk, created by the \"SMOOTH\" function or an afiliate"]
@variables TEMPVARSMOOTHED3_Relative_Behavioral_Risk(t) = TEMPVAR3_Relative_Behavioral_Risk [description = "TEMPVARSMOOTHED3_Relative_Behavioral_Risk, created by the \"SMOOTH\" function or an afiliate"]
@variables Relative_Behavioral_Risk(t)  [description = "Relative_Behavioral_Risk"]
@variables Relative_Contact_Density(t)  [description = "Relative_Contact_Density"]
@variables Serious_Cases(t)  [description = "Serious_Cases"]
@variables Transmission_Rate(t)  [description = "Transmission_Rate"]
 
    
#définition des tables:

PARAMETERS_SEPARATOR_base =Vector{Float64}([0.0,0.0,])
PARAMETERS_SEPARATOR_ranges = Vector{Float64}([0.0,0.0,])
PARAMETERS_SEPARATOR(t)=LinearInterpolation(PARAMETERS_SEPARATOR_base,PARAMETERS_SEPARATOR_ranges)(t)
@register_symbolic PARAMETERS_SEPARATOR(t)

#définition des equations:
eqs = [
    t_plus ~ t + (TIME_STEP / 2)
    	D(Deaths) ~ Dying
	D(Exposed) ~ Infecting - Advancing
	D(Infected) ~ Advancing + Importing_Infected - Dying - Recovering
	D(Recovered) ~ Recovering
	D(Susceptible) ~  - Infecting
	Active_Infected ~ (Infected) * ((1) - (Isolation_Effectiveness))
	Advancing ~ (Exposed) / (Incubation_Time)
	Dying ~ (Infected) * ((Fatality_Rate) / (Infection_Duration))
	Effect_of_Season ~ (1) - ((Seasonal_Amplitude) + ((Seasonal_Amplitude) * (((1) + ( cos((2) * ((3.14159) * (((t) - (Peak_Season)) / (Seasonal_Period)))))) / (2))))
	Fatality_Rate ~ (Untreated_Fatality_Rate) + (((Treated_Fatality_Rate) - (Untreated_Fatality_Rate)) / ((1) + ((Hospital_Strain) ^ (Hospital_Capacity_Sensitivity))))
	Fraction_Susceptible ~ (Susceptible) / (Initial_Population)
	Hospital_Strain ~ (Serious_Cases) / (Hospital_Capacity)
	Importing_Infected ~ (N_Imported_Infections) * ((IfElse.ifelse(t_plus > Import_Time, IfElse.ifelse(t_plus < (Import_Time + TIME_STEP), 1.0, 0.0),0.0)) / (TIME_STEP))
	Infecting ~ (Active_Infected) * ((Transmission_Rate) * (Effect_of_Season))
	Initial_Uncontrolled_Transmission_Rate ~ (R0) / (Infection_Duration)
	TEMPVAR1_Isolation_Effectiveness ~ (IfElse.ifelse( t<(Import_Time),0,(Potential_Isolation_Effectiveness)))
	TEMPVAR2_Isolation_Effectiveness ~ (IfElse.ifelse( t<(Import_Time),0,(Potential_Isolation_Effectiveness)))
	TEMPVAR3_Isolation_Effectiveness ~ (IfElse.ifelse( t<(Import_Time),0,(Potential_Isolation_Effectiveness)))
	D(TEMPVARSMOOTHED1_Isolation_Effectiveness) ~ ((IfElse.ifelse( t<(Import_Time),0,(Potential_Isolation_Effectiveness)))-TEMPVARSMOOTHED1_Isolation_Effectiveness) /((Isolation_Reaction_Time)/3)
	D(TEMPVARSMOOTHED2_Isolation_Effectiveness) ~ (TEMPVARSMOOTHED1_Isolation_Effectiveness-TEMPVARSMOOTHED2_Isolation_Effectiveness) /((Isolation_Reaction_Time)/3)
	D(TEMPVARSMOOTHED3_Isolation_Effectiveness) ~ (TEMPVARSMOOTHED2_Isolation_Effectiveness-TEMPVARSMOOTHED3_Isolation_Effectiveness) /((Isolation_Reaction_Time)/3)
	Isolation_Effectiveness ~ (TEMPVARSMOOTHED3_Isolation_Effectiveness) / ((1) + ((Public_Health_Strain) ^ (Public_Health_Capacity_Sensitivity)))
	Public_Health_Strain ~ (Infected) / (Public_Health_Capacity)
	Recovering ~ (Infected) / ((Infection_Duration) * ((1) - (Fatality_Rate)))
	TEMPVAR1_Relative_Behavioral_Risk ~ ((1) - (IfElse.ifelse( t<(Import_Time),0,(Behavioral_Risk_Reduction))))
	TEMPVAR2_Relative_Behavioral_Risk ~ ((1) - (IfElse.ifelse( t<(Import_Time),0,(Behavioral_Risk_Reduction))))
	TEMPVAR3_Relative_Behavioral_Risk ~ ((1) - (IfElse.ifelse( t<(Import_Time),0,(Behavioral_Risk_Reduction))))
	D(TEMPVARSMOOTHED1_Relative_Behavioral_Risk) ~ (((1) - (IfElse.ifelse( t<(Import_Time),0,(Behavioral_Risk_Reduction))))-TEMPVARSMOOTHED1_Relative_Behavioral_Risk) /((Behavior_Reaction_Time)/3)
	D(TEMPVARSMOOTHED2_Relative_Behavioral_Risk) ~ (TEMPVARSMOOTHED1_Relative_Behavioral_Risk-TEMPVARSMOOTHED2_Relative_Behavioral_Risk) /((Behavior_Reaction_Time)/3)
	D(TEMPVARSMOOTHED3_Relative_Behavioral_Risk) ~ (TEMPVARSMOOTHED2_Relative_Behavioral_Risk-TEMPVARSMOOTHED3_Relative_Behavioral_Risk) /((Behavior_Reaction_Time)/3)
	Relative_Behavioral_Risk ~ TEMPVARSMOOTHED3_Relative_Behavioral_Risk
	Relative_Contact_Density ~ (1) / ((1) + ((Contact_Density_Decline) * ((1) - (Fraction_Susceptible))))
	Serious_Cases ~ (Infected) * (Fraction_Requiring_Hospitalization)
	Transmission_Rate ~ (Initial_Uncontrolled_Transmission_Rate) * ((Relative_Behavioral_Risk) * ((Fraction_Susceptible) * (Relative_Contact_Density)))
    
]
    
#il faut maintenant définir le solveur: 
    
@named sys= ODESystem(eqs)
sys= structural_simplify(sys)
prob= ODEProblem(sys,[],(0,300), solver=RK4, dt=0, dtmax=0)
solved=solve(prob)

#plot(solved)
    